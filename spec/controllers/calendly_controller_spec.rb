require 'rails_helper'

RSpec.describe CalendlyController, type: :controller do
  let(:signing_key) { 'test_signing_key_123' }
  let(:timestamp) { Time.zone.now.to_i.to_s }

  let(:calendly_event_type_uri) { 'https://api.calendly.com/event_types/abc123' }
  let(:calendly_event_type_uris) { { 'call0' => calendly_event_type_uri } }
  let!(:admin_user) { FactoryBot.create(:admin_user, calendly_event_type_uris: calendly_event_type_uris) }
  let!(:parent) { FactoryBot.create(:parent) }
  let!(:child) { FactoryBot.create(:child, parent1: parent) }
  let(:child_support) { child.child_support }

  let(:event_uri) { 'https://api.calendly.com/scheduled_events/event123' }

  let(:invitee_created_payload) do
    {
      'event' => 'invitee.created',
      'payload' => {
        'event' => event_uri,
        'uri' => 'https://api.calendly.com/scheduled_events/event123/invitees/invitee456',
        'email' => 'parent@example.com',
        'name' => 'Test Parent',
        'tracking' => {
          'utm_source' => '1001mots',
          'utm_campaign' => 'call0',
          'utm_content' => parent.security_token
        },
        'questions_and_answers' => []
      }
    }
  end

  let(:invitee_canceled_payload) do
    {
      'event' => 'invitee.canceled',
      'payload' => {
        'event' => event_uri,
        'cancellation' => {
          'reason' => 'No longer available'
        }
      }
    }
  end

  let(:scheduled_event_response) do
    {
      'resource' => {
        'uri' => event_uri,
        'name' => 'Appel 0',
        'start_time' => '2026-01-15T10:00:00Z',
        'end_time' => '2026-01-15T10:30:00Z',
        'event_type' => calendly_event_type_uri,
        'status' => 'active'
      }
    }
  end

  before do
    stub_const('CalendlyController::CALENDLY_WEBHOOK_SIGNING_KEY', signing_key)

    stub_request(:get, event_uri)
      .to_return(status: 200, body: scheduled_event_response.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  def compute_signature(ts, body)
    data = "#{ts}.#{body}"
    "t=#{ts},v1=#{OpenSSL::HMAC.hexdigest('sha256', signing_key, data)}"
  end

  describe 'POST #webhooks' do
    context 'with valid signature' do
      context 'for invitee.created event' do
        it 'returns http success' do
          body = invitee_created_payload.to_json
          request.headers['Calendly-Webhook-Signature'] = compute_signature(timestamp, body)
          request.headers['Content-Type'] = 'application/json'

          post :webhooks, body: body, as: :json

          expect(response).to have_http_status(:ok)
        end

        it 'creates a ScheduledCall' do
          body = invitee_created_payload.to_json
          request.headers['Calendly-Webhook-Signature'] = compute_signature(timestamp, body)
          request.headers['Content-Type'] = 'application/json'

          expect {
            post :webhooks, body: body, as: :json
          }.to change(ScheduledCall, :count).by(1)
        end
      end

      context 'for invitee.canceled event' do
        let!(:scheduled_call) do
          ScheduledCall.create!(
            calendly_event_uri: event_uri,
            status: 'scheduled'
          )
        end

        it 'returns http success' do
          body = invitee_canceled_payload.to_json
          request.headers['Calendly-Webhook-Signature'] = compute_signature(timestamp, body)
          request.headers['Content-Type'] = 'application/json'

          post :webhooks, body: body, as: :json

          expect(response).to have_http_status(:ok)
        end

        it 'updates the ScheduledCall status' do
          body = invitee_canceled_payload.to_json
          request.headers['Calendly-Webhook-Signature'] = compute_signature(timestamp, body)
          request.headers['Content-Type'] = 'application/json'

          post :webhooks, body: body, as: :json

          expect(scheduled_call.reload.status).to eq('canceled')
        end
      end

      context 'for unknown event type' do
        let(:unknown_payload) do
          { 'event' => 'unknown.event', 'payload' => {} }
        end

        it 'returns http success' do
          body = unknown_payload.to_json
          request.headers['Calendly-Webhook-Signature'] = compute_signature(timestamp, body)
          request.headers['Content-Type'] = 'application/json'

          post :webhooks, body: body, as: :json

          expect(response).to have_http_status(:ok)
        end
      end
    end

    context 'with invalid signature' do
      it 'returns http unauthorized' do
        body = invitee_created_payload.to_json
        request.headers['Calendly-Webhook-Signature'] = 't=123,v1=invalid_signature'
        request.headers['Content-Type'] = 'application/json'

        post :webhooks, body: body, as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'does not create a ScheduledCall' do
        body = invitee_created_payload.to_json
        request.headers['Calendly-Webhook-Signature'] = 't=123,v1=invalid_signature'
        request.headers['Content-Type'] = 'application/json'

        expect {
          post :webhooks, body: body, as: :json
        }.not_to change(ScheduledCall, :count)
      end
    end

    context 'with missing signature' do
      it 'returns http unauthorized' do
        request.headers['Content-Type'] = 'application/json'
        post :webhooks, body: invitee_created_payload.to_json, as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with expired timestamp' do
      it 'returns http unauthorized' do
        old_timestamp = (Time.zone.now - 2.hours).to_i.to_s
        body = invitee_created_payload.to_json
        request.headers['Calendly-Webhook-Signature'] = compute_signature(old_timestamp, body)
        request.headers['Content-Type'] = 'application/json'

        post :webhooks, body: body, as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with empty request body' do
      it 'returns an error status' do
        request.headers['Calendly-Webhook-Signature'] = compute_signature(timestamp, '')
        request.headers['Content-Type'] = 'application/json'

        post :webhooks, as: :json

        # Empty body causes signature mismatch since actual body != signed body
        expect(response).to have_http_status(:unauthorized).or have_http_status(:bad_request)
      end
    end

    context 'when signing key is not configured' do
      before do
        stub_const('CalendlyController::CALENDLY_WEBHOOK_SIGNING_KEY', nil)
      end

      it 'returns http internal_server_error' do
        request.headers['Content-Type'] = 'application/json'
        post :webhooks, body: invitee_created_payload.to_json, as: :json

        expect(response).to have_http_status(:internal_server_error)
      end
    end

    context 'timezone isolation' do
      # Puma réutilise ses threads, il maintient un pool de threads fixes (ex. 5 threads).
      # Chaque requête entrante est assignée à un thread disponible.
      # Une fois la requête terminée, le thread attend la prochaine requête — il n'est pas détruit.
      # Time.zone = est une variable de thread
      # Time.zone = 'America/New_York' modifies cette variable sur le thread ET persiste
      # Il y avait un bug intermittent où si une requête modifiait Time.zone et ne le réinitialisait pas, la requête suivante traitée par le même thread aurait encore Time.zone réglé sur 'America/New_York', ce qui causait un comportement inattendu.

      let(:program_message_service_double) { instance_double(ProgramMessageService, call: nil, errors: []) }

      before do
        allow(ProgramMessageService).to receive(:new).and_return(program_message_service_double)
        allow(program_message_service_double).to receive(:call).and_return(program_message_service_double)
      end

      it 'restores Europe/Paris after request even when thread had a different timezone' do
        Thread.current[:time_zone] = ActiveSupport::TimeZone['America/New_York']

        body = invitee_created_payload.to_json
        request.headers['Calendly-Webhook-Signature'] = compute_signature(timestamp, body)
        request.headers['Content-Type'] = 'application/json'
        post :webhooks, body: body, as: :json

        expect(Time.zone.name).to eq('Europe/Paris')
      end

      it 'uses Europe/Paris timezone during request when thread had a different timezone' do
        Thread.current[:time_zone] = ActiveSupport::TimeZone['America/New_York']

        zone_during_request = nil
        allow_any_instance_of(Calendly::ProcessInviteeCreatedService).to receive(:call).and_wrap_original do |original|
          zone_during_request = Time.zone.name
          original.call
        end

        body = invitee_created_payload.to_json
        request.headers['Calendly-Webhook-Signature'] = compute_signature(timestamp, body)
        request.headers['Content-Type'] = 'application/json'
        post :webhooks, body: body, as: :json

        expect(zone_during_request).to eq('Europe/Paris')
      end
    end

    context 'when service returns errors' do
      let(:invalid_payload) do
        payload = invitee_created_payload.deep_dup
        payload['payload']['tracking']['utm_content'] = 'invalid_token'
        payload
      end

      it 'still returns http success' do
        body = invalid_payload.to_json
        request.headers['Calendly-Webhook-Signature'] = compute_signature(timestamp, body)
        request.headers['Content-Type'] = 'application/json'

        post :webhooks, body: body, as: :json

        expect(response).to have_http_status(:ok)
      end
    end
  end
end
