require 'rails_helper'

RSpec.describe Calendly::ProcessInviteeCanceledService do
  let(:event_uri) { 'https://api.calendly.com/scheduled_events/event123' }

  let!(:scheduled_call) do
    ScheduledCall.create!(
      calendly_event_uri: event_uri,
      status: 'scheduled',
      scheduled_at: 1.day.from_now
    )
  end

  let(:payload) do
    {
      'event' => 'invitee.canceled',
      'payload' => {
        'event' => event_uri,
        'uri' => 'https://api.calendly.com/scheduled_events/event123/invitees/invitee456',
        'cancellation' => {
          'canceled_at' => '2026-01-10T10:00:00Z',
          'reason' => 'Family emergency',
          'canceler_type' => 'invitee'
        }
      }
    }
  end

  subject { described_class.new(payload: payload) }

  describe '#call' do
    context 'when ScheduledCall exists' do
      it 'updates the ScheduledCall status to canceled' do
        subject.call
        expect(scheduled_call.reload.status).to eq('canceled')
      end

      it 'sets canceled_at from payload' do
        subject.call
        expect(scheduled_call.reload.canceled_at).to eq(Time.zone.parse('2026-01-10T10:00:00Z'))
      end

      it 'sets cancellation_reason from payload' do
        subject.call
        expect(scheduled_call.reload.cancellation_reason).to eq('Family emergency')
      end

      it 'stores the raw payload' do
        subject.call
        expect(scheduled_call.reload.raw_payload).to eq(payload)
      end

      it 'returns self with no errors' do
        result = subject.call
        expect(result.errors).to be_empty
      end

      it 'returns the scheduled_call' do
        result = subject.call
        expect(result.scheduled_call).to eq(scheduled_call)
      end
    end

    context 'when cancellation reason is not provided' do
      before do
        payload['payload']['cancellation'] = {
          'canceled_at' => '2026-01-10T10:00:00Z',
          'canceler_type' => 'host'
        }
      end

      it 'uses canceler_type as reason' do
        subject.call
        expect(scheduled_call.reload.cancellation_reason).to eq('host')
      end
    end

    context 'when canceled_at is not provided' do
      before do
        payload['payload']['cancellation'] = {
          'reason' => 'No longer available'
        }
      end

      it 'uses current time' do
        subject.call
        expect(scheduled_call.reload.canceled_at).to be_within(1.second).of(Time.zone.now)
      end
    end

    context 'when ScheduledCall does not exist' do
      let(:payload) do
        {
          'event' => 'invitee.canceled',
          'payload' => {
            'event' => 'https://api.calendly.com/scheduled_events/unknown',
            'cancellation' => {
              'reason' => 'Test'
            }
          }
        }
      end

      it 'returns an error' do
        result = subject.call
        expect(result.errors).to include(hash_including(message: "Aucun ScheduledCall trouvé pour cet événement"))
      end

      it 'does not modify any records' do
        expect { subject.call }.not_to change { ScheduledCall.count }
      end
    end

    context 'when event URI is missing from payload' do
      let(:payload) do
        {
          'event' => 'invitee.canceled',
          'payload' => {
            'cancellation' => {
              'reason' => 'Test'
            }
          }
        }
      end

      it 'returns an error' do
        result = subject.call
        expect(result.errors).to include(hash_including(message: "L'URI de l'événement est manquant dans le payload"))
      end
    end

    context 'when cancellation object is empty' do
      before do
        payload['payload']['cancellation'] = {}
      end

      it 'still updates status to canceled' do
        subject.call
        expect(scheduled_call.reload.status).to eq('canceled')
      end

      it 'sets canceled_at to current time' do
        subject.call
        expect(scheduled_call.reload.canceled_at).to be_within(1.second).of(Time.zone.now)
      end
    end
  end
end
