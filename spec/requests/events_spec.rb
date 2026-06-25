require 'rails_helper'

RSpec.describe 'EventsController#spot_hit_rcs_data', type: :request do
  include ActiveJob::TestHelper

  let(:path) { '/spot_hit/rcs_data' }
  let(:campaign_id) { 'campaign-123' }
  let(:parent) { FactoryBot.create(:parent, phone_number: '0755802002') }
  # phone_number is normalized to e164 by Parent#format_phone_number on save
  let(:phone_e164) { parent.reload.phone_number }

  # The controller only parses and enqueues; run the job inline so these specs
  # assert the end-to-end behaviour.
  def post_rcs(payload)
    perform_enqueued_jobs do
      post path, params: payload.to_json, headers: { 'CONTENT_TYPE' => 'application/json' }
    end
  end

  before { allow(Rollbar).to receive(:error) }

  describe 'enqueuing' do
    it 'enqueues the processing job with the parsed payload and returns ok' do
      payload = { 'events' => [] }

      expect do
        post path, params: payload.to_json, headers: { 'CONTENT_TYPE' => 'application/json' }
      end.to have_enqueued_job(Events::TextMessage::ProcessRcsDataJob).with(payload)

      expect(response).to have_http_status(:ok)
    end

    it 'does not enqueue a job for invalid JSON' do
      expect do
        post path, params: 'not-json', headers: { 'CONTENT_TYPE' => 'application/json' }
      end.not_to have_enqueued_job(Events::TextMessage::ProcessRcsDataJob)

      expect(response).to have_http_status(:bad_request)
    end
  end

  describe 'messageStatusChanged' do
    let!(:text_message) do
      FactoryBot.create(
        :text_message,
        related: parent,
        spot_hit_rcs_id: campaign_id,
        spot_hit_status: 0,
        originated_by_app: true
      )
    end

    def status_payload(message_status_changed_overrides = {})
      {
        'events' => [
          {
            'on' => '2026-06-23T10:00:00Z',
            'messageStatusChanged' => {
              'status' => 'DELIVERED',
              'userId' => phone_e164,
              'context' => { 'campaign_id' => campaign_id }
            }.merge(message_status_changed_overrides)
          }
        ]
      }
    end

    it 'updates spot_hit_status from the mapped RCS status' do
      post_rcs(status_payload)

      expect(response).to have_http_status(:ok)
      expect(text_message.reload.spot_hit_status).to eq(1) # DELIVERED -> Livré
    end

    it 'flags the message as fallback when channelId is fallback' do
      post_rcs(status_payload('channelId' => 'fallback'))

      expect(text_message.reload.is_fallback).to be(true)
    end

    it 'does not flag fallback for the default channel' do
      post_rcs(status_payload('channelId' => 'rcs'))

      expect(text_message.reload.is_fallback).to be(false)
    end

    it 'ignores a pending status mapped to 0 (QUEUED)' do
      post_rcs(status_payload('status' => 'QUEUED'))

      expect(text_message.reload.spot_hit_status).to eq(0)
    end

    it 'logs and skips an unknown status without changing the message' do
      post_rcs(status_payload('status' => 'NOT_A_REAL_STATUS'))

      expect(response).to have_http_status(:ok)
      expect(text_message.reload.spot_hit_status).to eq(0)
      expect(Rollbar).to have_received(:error).with('spot_hit_rcs_data: unknown rcs status', anything)
    end

    it 'stores the RCS error code when an error is present' do
      post_rcs(
        status_payload(
          'status' => 'DELIVERY_FAILED',
          'error' => { 'code' => 'E42', 'details' => 'channel rejected' }
        )
      )

      text_message.reload
      expect(text_message.rcs_error_code).to eq('E42')
      expect(text_message.spot_hit_status).to eq(4) # DELIVERY_FAILED -> Échec
    end

    it 'logs when no text_message matches the campaign' do
      text_message.update!(spot_hit_rcs_id: 'other-campaign')

      post_rcs(status_payload)

      expect(response).to have_http_status(:ok)
      expect(Rollbar).to have_received(:error).with('spot_hit_rcs_data: text_message not found', anything)
    end
  end

  describe 'userMessageReceived' do
    def received_payload(user_message_received_overrides = {}, event_overrides = {})
      {
        'events' => [
          {
            'on' => '2026-06-23T10:00:00Z',
            'userMessageReceived' => {
              'userId' => phone_e164,
              'context' => { 'campaign_id' => campaign_id },
              'content' => { 'text' => 'Bonjour' }
            }.merge(user_message_received_overrides)
          }.merge(event_overrides)
        ]
      }
    end

    it 'creates an inbound text message for the parent' do
      expect { post_rcs(received_payload) }.to change(Events::TextMessage, :count).by(1)

      expect(response).to have_http_status(:ok)
      message = Events::TextMessage.last
      expect(message).to have_attributes(
        related: parent,
        body: 'Bonjour',
        spot_hit_rcs_id: campaign_id,
        spot_hit_status: 1,
        originated_by_app: false
      )
      expect(message.occurred_at).to eq(Time.zone.parse('2026-06-23T10:00:00Z'))
    end

    it 'does not create a message when the parent is unknown' do
      expect do
        post_rcs(received_payload('userId' => '0668029999'))
      end.not_to change(Events::TextMessage, :count)

      expect(response).to have_http_status(:ok)
      expect(Rollbar).to have_received(:error).with('spot_hit_rcs_data: parent not found', anything)
    end

    it 'does not create a message when the text content is missing' do
      expect do
        post_rcs(received_payload('content' => {}))
      end.not_to change(Events::TextMessage, :count)

      expect(response).to have_http_status(:ok)
    end

    it 'skips the event and logs when the date is missing' do
      payload = received_payload({}, {}).tap { |p| p['events'].first.delete('on') }

      expect { post_rcs(payload) }.not_to change(Events::TextMessage, :count)

      expect(response).to have_http_status(:ok)
      expect(Rollbar).to have_received(:error).with('spot_hit_rcs_data: event without date', anything)
    end
  end

  describe 'malformed payloads' do
    it 'returns ok and logs for an event without a known content key' do
      post_rcs('events' => [{ 'on' => '2026-06-23T10:00:00Z' }])

      expect(response).to have_http_status(:ok)
      expect(Rollbar).to have_received(:error).with('spot_hit_rcs_data: event without content', anything)
    end

    it 'returns ok for an empty events list' do
      post_rcs('events' => [])

      expect(response).to have_http_status(:ok)
    end

    it 'returns bad_request for invalid JSON' do
      post path, params: 'not-json', headers: { 'CONTENT_TYPE' => 'application/json' }

      expect(response).to have_http_status(:bad_request)
      expect(Rollbar).to have_received(:error).with('spot_hit_rcs_data: invalid payload JSON', anything)
    end
  end
end
