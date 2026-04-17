require 'rails_helper'

RSpec.describe Calendly::ProcessInviteeCanceledService do
  let(:event_uri) { 'https://api.calendly.com/scheduled_events/event123' }
  let!(:admin_user) { FactoryBot.create(:admin_user) }
  let!(:parent) { FactoryBot.create(:parent) }
  let!(:child) { FactoryBot.create(:child, parent1: parent) }
  let!(:child_support) do
    cs = child.child_support
    cs.update!(supporter: admin_user)
    cs
  end

  let!(:scheduled_call) do
    FactoryBot.create(:scheduled_call,
      calendly_event_uri: event_uri,
      status: 'scheduled',
      scheduled_at: 1.day.from_now,
      call_session: 1,
      child_support: child_support,
      parent: parent
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

  let(:one_off_service) { instance_double(Calendly::CreateOneOffEventTypeService, errors: []) }
  let(:program_message_service) { instance_double(ProgramMessageService, errors: []) }

  subject { described_class.new(payload: payload) }

  before do
    parent.update!(calendly_booking_urls: { 'call1' => 'https://calendly.com/rebooking-url' })
    allow(Calendly::CreateOneOffEventTypeService).to receive(:new).and_return(one_off_service)
    allow(one_off_service).to receive(:call).and_return(one_off_service)
    allow(ProgramMessageService).to receive(:new).and_return(program_message_service)
    allow(program_message_service).to receive(:call).and_return(program_message_service)
  end

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

      it 'calls CreateOneOffEventTypeService with the correct arguments' do
        expect(Calendly::CreateOneOffEventTypeService).to receive(:new).with(
          child_support: child_support,
          call_session: 1
        )
        subject.call
      end

      it 'sends the rebooking message via ProgramMessageService' do
        expect(ProgramMessageService).to receive(:new).with(
          anything,
          anything,
          ["parent.#{parent.id}"],
          include('https://calendly.com/rebooking-url')
        )
        subject.call
      end

      it 'updates calendly_last_booking_dates on the parent' do
        subject.call
        parent.reload
        expect(parent.calendly_last_booking_dates['call1']).to eq(Time.zone.today.to_s)
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

    context 'when ScheduledCall does not exist' do
      let(:payload) do
        {
          'event' => 'invitee.canceled',
          'payload' => {
            'event' => 'https://api.calendly.com/scheduled_events/unknown',
            'cancellation' => { 'reason' => 'Test' }
          }
        }
      end

      it 'returns an error' do
        result = subject.call
        expect(result.errors).to include(hash_including(message: 'Aucun ScheduledCall trouvé pour cet événement'))
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
            'cancellation' => { 'reason' => 'Test' }
          }
        }
      end

      it 'returns an error' do
        result = subject.call
        expect(result.errors).to include(hash_including(message: "L'URI de l'événement est manquant dans le payload"))
      end
    end

    context 'when child_support is missing on scheduled_call' do
      before { scheduled_call.update_column(:child_support_id, nil) }

      it 'returns an error' do
        result = subject.call
        expect(result.errors).to include(hash_including(message: 'Le ScheduledCall ne dispose pas de child_support'))
      end

      it 'does not call CreateOneOffEventTypeService' do
        expect(Calendly::CreateOneOffEventTypeService).not_to receive(:new)
        subject.call
      end
    end

    context 'when call_session is missing on scheduled_call' do
      before { scheduled_call.update_column(:call_session, nil) }

      it 'returns an error' do
        result = subject.call
        expect(result.errors).to include(hash_including(message: 'Le ScheduledCall ne dispose pas de call_session'))
      end

      it 'does not call CreateOneOffEventTypeService' do
        expect(Calendly::CreateOneOffEventTypeService).not_to receive(:new)
        subject.call
      end
    end

    context 'when CreateOneOffEventTypeService fails' do
      before do
        allow(one_off_service).to receive(:errors).and_return([{ message: 'Échec API Calendly' }])
      end

      it 'returns an error' do
        result = subject.call
        expect(result.errors).to include(hash_including(message: 'Échec de la création du nouvel one-off event type après annulation'))
      end

      it 'does not send a rebooking message' do
        expect(ProgramMessageService).not_to receive(:new)
        subject.call
      end
    end

    context 'when parent is missing on scheduled_call' do
      before { scheduled_call.update_column(:parent_id, nil) }

      it 'returns an error' do
        result = subject.call
        expect(result.errors).to include(hash_including(message: 'Le ScheduledCall ne dispose pas de parent'))
      end

      it 'does not send a rebooking message' do
        expect(ProgramMessageService).not_to receive(:new)
        subject.call
      end
    end

    context 'when calendly booking URL is missing after recreation' do
      before { parent.update!(calendly_booking_urls: {}) }

      it 'returns an error' do
        result = subject.call
        expect(result.errors).to include(hash_including(
          message: "Le lien calendly d'une nouvelle prise de rdv n'a pas pu être récupéré"
        ))
      end

      it 'does not send a rebooking message' do
        expect(ProgramMessageService).not_to receive(:new)
        subject.call
      end
    end

    context 'when ProgramMessageService fails' do
      before do
        allow(program_message_service).to receive(:errors).and_return([{ message: 'Échec envoi SMS' }])
      end

      it 'returns an error' do
        result = subject.call
        expect(result.errors).to include(hash_including(message: "L'envoi du message de reprise de RDV a échoué"))
      end

      it 'does not update calendly_last_booking_dates' do
        subject.call
        parent.reload
        expect(parent.calendly_last_booking_dates).to eq({})
      end
    end
  end
end