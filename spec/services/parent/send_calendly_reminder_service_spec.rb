require 'rails_helper'

RSpec.describe Parent::SendCalendlyReminderService do
  include ActiveJob::TestHelper

  # Cohorte démarrée le lundi 2026-02-09 => session d'appel 1 du 2026-03-09 au 2026-03-22
  # (set_calls_dates : call1 = started_at + 28 jours / + 41 jours).
  let(:group_started_at) { Date.new(2026, 2, 9) }
  let(:call1_start) { group_started_at + 28.days } # 2026-03-09
  let(:call1_end) { group_started_at + 41.days } # 2026-03-22
  let(:today) { Date.new(2026, 3, 16) } # en cours de session
  let(:initial_message_date) { today - 2.days } # 1er SMS envoyé à J-2
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

  let(:parent) do
    FactoryBot.create(:parent,
                      calendly_booking_urls: { 'call1' => 'https://calendly.com/d/abc-def/appel?utm_source=1001mots' },
                      calendly_initial_booking_dates: { 'call1' => initial_message_date.to_s })
  end

  let(:child) do
    FactoryBot.create(:child,
                      parent1: parent,
                      group: group,
                      group_status: 'active',
                      should_contact_parent1: true)
  end

  let(:child_support) { child.child_support.tap { |cs| cs.update!(supporter: supporter, call1_status: nil) } }

  subject { described_class.new(date: today) }

  before do
    ActiveJob::Base.queue_adapter = :test
    stub_const('ENV', ENV.to_h.merge('BETA_TEST_CALLERS_EMAIL' => beta_test_email))
    child_support # trigger setup
  end

  describe '#initialize' do
    it 'initializes with no errors' do
      expect(subject.errors).to eq([])
    end
  end

  describe '#call' do
    context 'when BETA_TEST_CALLERS_EMAIL is not set' do
      before { stub_const('ENV', ENV.to_h.merge('BETA_TEST_CALLERS_EMAIL' => '')) }

      it 'returns an error and does not send' do
        result = subject.call
        expect(result.errors).not_to be_empty
        expect(result.errors.first[:error]).to include('BETA_TEST_CALLERS_EMAIL')
      end
    end

    context 'when a parent received the initial booking SMS two days ago' do
      it 'returns no errors' do
        result = subject.call
        expect(result.errors).to be_empty
      end

      it 'schedules an Aircall::SendCalendlyReminderJob' do
        expect { subject.call }.to have_enqueued_job(Aircall::SendCalendlyReminderJob)
          .with(child_support.id, 1, parent.id, 'https://calendly.com/d/abc-def/appel?utm_source=1001mots')
      end

      it 'does not create the Event yet (it is created at job execution)' do
        expect { subject.call }.not_to change(Event, :count)
      end

      it 'does not enqueue Aircall::SendMessageJob directly (the reminder job will)' do
        expect { subject.call }.not_to have_enqueued_job(Aircall::SendMessageJob)
      end

      it 'schedules the reminder job at 14h the same day' do
        subject.call
        expected_time = ActiveSupport::TimeZone['Europe/Paris'].parse("#{today.strftime('%Y-%m-%d')} 14:00")
        expect(Aircall::SendCalendlyReminderJob).to have_been_enqueued.at(expected_time)
      end
    end

    context 'when the initial booking SMS date is stored as a datetime string (backfill)' do
      before { parent.update!(calendly_initial_booking_dates: { 'call1' => "#{initial_message_date} 17:00:00 +0100" }) }

      it 'schedules the reminder job' do
        expect { subject.call }.to have_enqueued_job(Aircall::SendCalendlyReminderJob)
      end
    end

    context 'when the initial booking SMS was sent at another date than two days ago' do
      before { parent.update!(calendly_initial_booking_dates: { 'call1' => (today - 1.day).to_s }) }

      it 'does not schedule the reminder job' do
        expect { subject.call }.not_to have_enqueued_job(Aircall::SendCalendlyReminderJob)
      end
    end

    context 'when the parent never received the initial booking SMS' do
      before { parent.update!(calendly_initial_booking_dates: {}) }

      it 'does not schedule the reminder job' do
        expect { subject.call }.not_to have_enqueued_job(Aircall::SendCalendlyReminderJob)
      end
    end

    context "when today is the last day of the family's booking window" do
      before do
        FactoryBot.create(:call_session_date_override,
                          admin_user: supporter,
                          group: group,
                          call_session: 1,
                          start_date: call1_start,
                          end_date: today)
      end

      it 'does not schedule the reminder job (too late to get appointments)' do
        expect { subject.call }.not_to have_enqueued_job(Aircall::SendCalendlyReminderJob)
      end
    end

    context "when the supporter's custom booking window is already over" do
      before do
        FactoryBot.create(:call_session_date_override,
                          admin_user: supporter,
                          group: group,
                          call_session: 1,
                          start_date: call1_start,
                          end_date: today - 3.days)
      end

      it 'does not schedule the reminder job' do
        expect { subject.call }.not_to have_enqueued_job(Aircall::SendCalendlyReminderJob)
      end
    end

    context 'when the supporter is not in BETA_TEST_CALLERS_EMAIL' do
      before { stub_const('ENV', ENV.to_h.merge('BETA_TEST_CALLERS_EMAIL' => 'other@example.com')) }

      it 'does not schedule the reminder job' do
        expect { subject.call }.not_to have_enqueued_job(Aircall::SendCalendlyReminderJob)
      end
    end

    context 'when the parent already has a scheduled call for the session' do
      before do
        FactoryBot.create(:scheduled_call, parent: parent, child_support: child_support, call_session: 1, status: 'scheduled')
      end

      it 'does not schedule the reminder job' do
        expect { subject.call }.not_to have_enqueued_job(Aircall::SendCalendlyReminderJob)
      end
    end

    context 'when the parent has a canceled scheduled call' do
      before do
        FactoryBot.create(:scheduled_call, :canceled, parent: parent, child_support: child_support, call_session: 1)
      end

      it 'schedules the reminder job (canceled call should not block)' do
        expect { subject.call }.to have_enqueued_job(Aircall::SendCalendlyReminderJob)
      end
    end

    context 'when the parent has no calendly booking url for the session' do
      before { parent.update!(calendly_booking_urls: {}) }

      it 'does not schedule the reminder job' do
        expect { subject.call }.not_to have_enqueued_job(Aircall::SendCalendlyReminderJob)
      end
    end

    context 'when the call status is already filled' do
      before { child_support.update!(call1_status: ChildSupport.human_attribute_name('call_status.1_ok')) }

      it 'does not schedule the reminder job' do
        expect { subject.call }.not_to have_enqueued_job(Aircall::SendCalendlyReminderJob)
      end
    end

    context 'when the supporter has no aircall_number_id' do
      before { supporter.update!(aircall_number_id: nil) }

      it 'does not schedule the reminder job' do
        expect { subject.call }.not_to have_enqueued_job(Aircall::SendCalendlyReminderJob)
      end
    end

    context "when the group has type_of_support 'without_calls'" do
      before { group.update!(type_of_support: 'without_calls') }

      it 'does not schedule the reminder job' do
        expect { subject.call }.not_to have_enqueued_job(Aircall::SendCalendlyReminderJob)
      end
    end

    context 'with batching per supporter' do
      let(:max_per_hour) { Parent::SendCalendlyReminderService::MAX_SMS_PER_HOUR_PER_SUPPORTER }

      let(:extra_parents) do
        Array.new(max_per_hour) do
          p = FactoryBot.create(:parent,
                                calendly_booking_urls: { 'call1' => 'https://calendly.com/d/abc/appel' },
                                calendly_initial_booking_dates: { 'call1' => initial_message_date.to_s })
          c = FactoryBot.create(:child, parent1: p, group: group, group_status: 'active', should_contact_parent1: true)
          c.child_support.update!(supporter: supporter, call1_status: nil)
          p
        end
      end

      before { extra_parents }

      it 'puts the first batch in the 14h slot and overflow in the 15h slot' do
        subject.call
        expected_14h = ActiveSupport::TimeZone['Europe/Paris'].parse("#{today.strftime('%Y-%m-%d')} 14:00").to_i
        expected_15h = ActiveSupport::TimeZone['Europe/Paris'].parse("#{today.strftime('%Y-%m-%d')} 15:00").to_i
        jobs_in_14h_slot = enqueued_jobs.select { |j| j[:at].to_i >= expected_14h && j[:at].to_i < expected_15h }
        jobs_in_15h_slot = enqueued_jobs.select { |j| j[:at].to_i >= expected_15h && j[:at].to_i < expected_15h + 3600 }
        expect(jobs_in_14h_slot.size).to eq(max_per_hour)
        expect(jobs_in_15h_slot.size).to eq(1) # the original parent
      end

      it 'schedules all jobs in the 14h slot at the same time (single supporter, no offset)' do
        subject.call
        expected_14h = ActiveSupport::TimeZone['Europe/Paris'].parse("#{today.strftime('%Y-%m-%d')} 14:00").to_i
        timestamps_in_14h_slot = enqueued_jobs
                                 .map { |j| j[:at].to_i }
                                 .select { |t| t >= expected_14h && t < expected_14h + 3600 }
        expect(timestamps_in_14h_slot.size).to eq(max_per_hour)
        expect(timestamps_in_14h_slot.uniq).to eq([expected_14h])
      end
    end

    context 'with two supporters, each with their own batch' do
      let(:second_supporter_email) { 'beta2@example.com' }
      let(:second_supporter) do
        FactoryBot.create(:admin_user,
                          user_role: 'caller',
                          email: second_supporter_email,
                          can_send_automatic_sms: true,
                          aircall_number_id: 99_999,
                          aircall_phone_number: '+33987654321',
                          calendly_user_uri: 'https://api.calendly.com/users/def456')
      end
      let(:second_parent) do
        FactoryBot.create(:parent,
                          calendly_booking_urls: { 'call1' => 'https://calendly.com/d/xyz/appel' },
                          calendly_initial_booking_dates: { 'call1' => initial_message_date.to_s })
      end
      let(:second_child) do
        FactoryBot.create(:child, parent1: second_parent, group: group, group_status: 'active', should_contact_parent1: true)
      end

      before do
        stub_const('ENV', ENV.to_h.merge('BETA_TEST_CALLERS_EMAIL' => "#{beta_test_email} #{second_supporter_email}"))
        second_child.child_support.update!(supporter: second_supporter, call1_status: nil)
      end

      it 'schedules one job per supporter in the 14h slot, staggered by one minute per supporter' do
        subject.call
        expected_14h = ActiveSupport::TimeZone['Europe/Paris'].parse("#{today.strftime('%Y-%m-%d')} 14:00").to_i
        expected_15h = ActiveSupport::TimeZone['Europe/Paris'].parse("#{today.strftime('%Y-%m-%d')} 15:00").to_i
        timestamps_in_14h_slot = enqueued_jobs
                                 .map { |j| j[:at].to_i }
                                 .select { |t| t >= expected_14h && t < expected_15h }
                                 .sort
        expect(timestamps_in_14h_slot).to eq([expected_14h, expected_14h + 60])
      end
    end
  end
end
