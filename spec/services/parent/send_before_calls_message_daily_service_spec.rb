require 'rails_helper'

RSpec.describe Parent::SendBeforeCallsMessageDailyService do
  # Cohorte démarrée le lundi 2026-02-02 => session d'appel 1 du 2026-03-02 au 2026-03-15
  # (set_calls_dates : call1 = started_at + 28 jours / + 41 jours).
  let(:group_started_at) { Date.new(2026, 2, 2) }
  let(:call1_start) { group_started_at + 28.days } # 2026-03-02
  let(:call1_end) { group_started_at + 41.days } # 2026-03-15
  let(:today) { call1_start - 3.days } # 2026-02-27, J-3 du début de session
  let(:beta_test_email) { 'beta@example.com' }

  let(:supporter) do
    FactoryBot.create(:admin_user,
                      user_role: 'caller',
                      email: beta_test_email,
                      can_send_automatic_sms: true,
                      aircall_number_id: 12_345,
                      aircall_phone_number: '+33123456789',
                      calendly_user_uri: 'https://api.calendly.com/users/abc123')
  end

  let(:group) do
    FactoryBot.create(:group,
                      started_at: group_started_at,
                      type_of_support: 'with_calls')
  end

  let(:parent) { FactoryBot.create(:parent) }

  let(:child) do
    FactoryBot.create(:child,
                      parent1: parent,
                      group: group,
                      group_status: 'active',
                      should_contact_parent1: true)
  end

  let(:child_support) { child.child_support.tap { |cs| cs.update!(supporter: supporter, call1_status: nil) } }

  let(:calls_message_service) { instance_double(Parent::SendBeforeCallsMessageService, errors: []) }
  let(:first_call_message_service) { instance_double(Parent::SendBeforeFirstCallMessageService, errors: []) }

  subject { described_class.new(date: today) }

  before do
    stub_const('ENV', ENV.to_h.merge('BETA_TEST_CALLERS_EMAIL' => beta_test_email))
    allow(Parent::SendBeforeCallsMessageService).to receive(:new).and_return(calls_message_service)
    allow(calls_message_service).to receive(:handle_group_message)
    allow(Parent::SendBeforeFirstCallMessageService).to receive(:new).and_return(first_call_message_service)
    allow(first_call_message_service).to receive(:handle_group_message)
    child_support # trigger setup
  end

  describe '#call' do
    context 'when BETA_TEST_CALLERS_EMAIL is not set' do
      before { stub_const('ENV', ENV.to_h.merge('BETA_TEST_CALLERS_EMAIL' => '')) }

      it 'returns an error and does not dispatch' do
        result = subject.call
        expect(result.errors).not_to be_empty
        expect(result.errors.first[:error]).to include('BETA_TEST_CALLERS_EMAIL')
        expect(calls_message_service).not_to have_received(:handle_group_message)
      end
    end

    context 'when the default session start date is in 3 days' do
      it 'dispatches the initial booking SMS for the family' do
        subject.call
        expect(Parent::SendBeforeCallsMessageService).to have_received(:new).with(date: today)
        expect(calls_message_service).to have_received(:handle_group_message).with(group, 1, [child_support.id])
      end

      it 'returns no errors' do
        expect(subject.call.errors).to be_empty
      end
    end

    context 'when the parent already received the initial booking SMS for this session' do
      before { parent.update!(calendly_initial_booking_dates: { 'call1' => today.to_s }) }

      it 'does not dispatch' do
        subject.call
        expect(calls_message_service).not_to have_received(:handle_group_message)
      end
    end

    context 'when the parent only has an initial booking SMS date from a previous support program' do
      before { parent.update!(calendly_initial_booking_dates: { 'call1' => (today - 1.year).to_s }) }

      it 'dispatches the initial booking SMS (the stale date must not block the new program)' do
        subject.call
        expect(calls_message_service).to have_received(:handle_group_message).with(group, 1, [child_support.id])
      end
    end

    context 'when the stored initial booking SMS date is unreadable' do
      before { parent.update!(calendly_initial_booking_dates: { 'call1' => 'invalid' }) }

      it 'does not dispatch (avoids sending in a loop since the date would never refresh)' do
        subject.call
        expect(calls_message_service).not_to have_received(:handle_group_message)
      end
    end

    context 'when the session start date is more than 3 days away' do
      let(:today) { call1_start - 10.days }

      it 'does not dispatch' do
        subject.call
        expect(calls_message_service).not_to have_received(:handle_group_message)
      end
    end

    context 'when the session has already started but the SMS was never sent (rattrapage)' do
      let(:today) { call1_start + 2.days }

      it 'dispatches the initial booking SMS' do
        subject.call
        expect(calls_message_service).to have_received(:handle_group_message).with(group, 1, [child_support.id])
      end
    end

    context 'when the session booking window is over' do
      let(:today) { call1_end + 1.day }

      it 'does not dispatch' do
        subject.call
        expect(calls_message_service).not_to have_received(:handle_group_message)
      end
    end

    context 'when the supporter customized the booking window with a later start date' do
      let!(:override) do
        FactoryBot.create(:call_session_date_override,
                          admin_user: supporter,
                          group: group,
                          call_session: 1,
                          start_date: call1_start + 7.days,
                          end_date: call1_end)
      end

      it 'does not dispatch at J-3 of the default date' do
        subject.call
        expect(calls_message_service).not_to have_received(:handle_group_message)
      end

      context 'at J-3 of the customized start date' do
        let(:today) { call1_start + 7.days - 3.days }

        it 'dispatches the initial booking SMS' do
          subject.call
          expect(calls_message_service).to have_received(:handle_group_message).with(group, 1, [child_support.id])
        end
      end
    end

    context "when the supporter's customized booking window is already over" do
      let!(:override) do
        FactoryBot.create(:call_session_date_override,
                          admin_user: supporter,
                          group: group,
                          call_session: 1,
                          start_date: call1_start,
                          end_date: call1_start + 4.days)
      end
      let(:today) { call1_start + 5.days }

      it 'does not dispatch' do
        subject.call
        expect(calls_message_service).not_to have_received(:handle_group_message)
      end
    end

    context 'when the supporter is not in BETA_TEST_CALLERS_EMAIL' do
      before { stub_const('ENV', ENV.to_h.merge('BETA_TEST_CALLERS_EMAIL' => 'other@example.com')) }

      it 'does not dispatch' do
        subject.call
        expect(calls_message_service).not_to have_received(:handle_group_message)
      end
    end

    context 'when the call status is already filled' do
      before { child_support.update!(call1_status: ChildSupport.human_attribute_name('call_status.1_ok')) }

      it 'does not dispatch' do
        subject.call
        expect(calls_message_service).not_to have_received(:handle_group_message)
      end
    end

    context 'for the call session 0' do
      # call0 : du started_at (2026-02-02) au started_at + 13 jours
      let(:today) { group_started_at - 3.days }

      before { child_support.update!(call0_status: nil) }

      it 'dispatches via Parent::SendBeforeFirstCallMessageService' do
        subject.call
        expect(Parent::SendBeforeFirstCallMessageService).to have_received(:new).with(group_id: group.id, date: today)
        expect(first_call_message_service).to have_received(:handle_group_message).with(group, [child_support.id])
      end
    end

    context 'when the sub-service reports errors' do
      let(:calls_message_service) { instance_double(Parent::SendBeforeCallsMessageService, errors: [{ error: 'boom' }]) }

      it 'collects them' do
        result = subject.call
        expect(result.errors).to include({ error: 'boom' })
      end
    end
  end
end
