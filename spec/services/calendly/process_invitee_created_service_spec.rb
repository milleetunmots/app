require 'rails_helper'

RSpec.describe Calendly::ProcessInviteeCreatedService do
  let(:calendly_event_type_uri) { 'https://api.calendly.com/event_types/abc123' }
  let(:calendly_event_type_uris) { { 'call0' => calendly_event_type_uri, 'call1' => calendly_event_type_uri } }
  let!(:admin_user) { FactoryBot.create(:admin_user, calendly_event_type_uris: calendly_event_type_uris) }
  let!(:parent) { FactoryBot.create(:parent) }
  let!(:child) { FactoryBot.create(:child, parent1: parent) }
  let(:child_support) { child.child_support }

  let(:event_uri) { 'https://api.calendly.com/scheduled_events/event123' }
  let(:invitee_uri) { 'https://api.calendly.com/scheduled_events/event123/invitees/invitee456' }

  let(:payload) do
    {
      'event' => 'invitee.created',
      'payload' => {
        'event' => event_uri,
        'uri' => invitee_uri,
        'email' => 'parent@example.com',
        'name' => 'Test Parent',
        'tracking' => {
          'utm_source' => '1001mots',
          'utm_campaign' => 'call0',
          'utm_content' => parent.security_token
        },
        'questions_and_answers' => [
          { 'question' => 'Commentaire', 'answer' => 'Test comment' }
        ]
      }
    }
  end

  let(:scheduled_event_response) do
    {
      'resource' => {
        'uri' => event_uri,
        'name' => 'Appel 0 - Test',
        'start_time' => '2026-01-15T10:00:00Z',
        'end_time' => '2026-01-15T10:30:00Z',
        'event_type' => calendly_event_type_uri,
        'status' => 'active'
      }
    }
  end

  subject { described_class.new(payload: payload) }

  before do
    stub_request(:get, event_uri)
      .to_return(status: 200, body: scheduled_event_response.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  describe '#call' do
    context 'when payload is valid' do
      it 'creates a new ScheduledCall' do
        expect { subject.call }.to change(ScheduledCall, :count).by(1)
      end

      it 'returns self with no errors' do
        result = subject.call
        expect(result.errors).to be_empty
      end

      it 'creates ScheduledCall with correct attributes' do
        result = subject.call
        scheduled_call = result.scheduled_call

        expect(scheduled_call.calendly_event_uri).to eq(event_uri)
        expect(scheduled_call.calendly_invitee_uri).to eq(invitee_uri)
        expect(scheduled_call.admin_user).to eq(admin_user)
        expect(scheduled_call.child_support).to eq(child_support)
        expect(scheduled_call.parent).to eq(parent)
        expect(scheduled_call.call_session).to eq(0)
        expect(scheduled_call.invitee_email).to eq('parent@example.com')
        expect(scheduled_call.invitee_name).to eq('Test Parent')
        expect(scheduled_call.status).to eq('scheduled')
      end

      it 'extracts event details from API' do
        result = subject.call
        scheduled_call = result.scheduled_call

        expect(scheduled_call.scheduled_at).to eq(Time.zone.parse('2026-01-15T10:00:00Z'))
        expect(scheduled_call.duration_minutes).to eq(30)
        expect(scheduled_call.event_type_name).to eq('Appel 0 - Test')
        expect(scheduled_call.event_type_uri).to eq(calendly_event_type_uri)
      end

      it 'extracts invitee comment from questions and answers' do
        result = subject.call
        expect(result.scheduled_call.invitee_comment).to include('Commentaire: Test comment')
      end

      it 'stores raw payload' do
        result = subject.call
        expect(result.scheduled_call.raw_payload).to eq(payload)
      end
    end

    context 'when security_token is missing' do
      before do
        payload['payload']['tracking']['utm_content'] = nil
      end

      it 'returns an error' do
        result = subject.call
        expect(result.errors).to include(hash_including(message: "Le security_token (utm_content) est manquant dans le payload"))
      end

      it 'does not create a ScheduledCall' do
        expect { subject.call }.not_to change(ScheduledCall, :count)
      end
    end

    context 'when parent is not found' do
      before do
        payload['payload']['tracking']['utm_content'] = 'invalid_token'
      end

      it 'returns an error' do
        result = subject.call
        expect(result.errors).to include(hash_including(message: "Aucun parent trouvé avec le security_token"))
      end
    end

    context 'when parent has no current child with child_support' do
      before do
        parent.children.destroy_all
      end

      it 'returns an error about missing child support' do
        result = subject.call
        expect(result.errors).to include(hash_including(message: "Aucune fiche de suivi trouvée pour ce parent"))
      end
    end

    context 'with different call sessions' do
      %w[call0 call1 call2 call3].each_with_index do |campaign, index|
        context "when utm_campaign is #{campaign}" do
          before do
            payload['payload']['tracking']['utm_campaign'] = campaign
          end

          it "extracts call_session as #{index}" do
            result = subject.call
            expect(result.scheduled_call.call_session).to eq(index)
          end
        end
      end
    end

    context 'when ScheduledCall already exists for event_uri' do
      let!(:existing_scheduled_call) do
        ScheduledCall.create!(
          calendly_event_uri: event_uri,
          status: 'scheduled'
        )
      end

      it 'updates the existing ScheduledCall' do
        expect { subject.call }.not_to change(ScheduledCall, :count)
      end

      it 'updates attributes on existing record' do
        subject.call
        existing_scheduled_call.reload
        expect(existing_scheduled_call.parent).to eq(parent)
        expect(existing_scheduled_call.child_support).to eq(child_support)
      end
    end

    context 'when API call to fetch event details fails' do
      before do
        stub_request(:get, event_uri)
          .to_return(status: 404, body: { 'message' => 'Not found' }.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'still creates the ScheduledCall with available data' do
        expect { subject.call }.to change(ScheduledCall, :count).by(1)
      end

      it 'logs the API error' do
        result = subject.call
        expect(result.errors).to include(hash_including(message: "Échec de la récupération de l'événement"))
      end
    end

    context 'when questions_and_answers is empty' do
      before do
        payload['payload']['questions_and_answers'] = []
      end

      it 'creates ScheduledCall with nil invitee_comment' do
        result = subject.call
        expect(result.scheduled_call.invitee_comment).to be_nil
      end
    end

    context 'when questions_and_answers has multiple entries' do
      before do
        payload['payload']['questions_and_answers'] = [
          { 'question' => 'Question 1', 'answer' => 'Answer 1' },
          { 'question' => 'Question 2', 'answer' => 'Answer 2' }
        ]
      end

      it 'concatenates all questions and answers' do
        result = subject.call
        expect(result.scheduled_call.invitee_comment).to include('Question 1: Answer 1')
        expect(result.scheduled_call.invitee_comment).to include('Question 2: Answer 2')
      end
    end
  end
end
