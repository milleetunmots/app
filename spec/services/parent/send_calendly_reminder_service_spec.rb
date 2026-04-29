require 'rails_helper'

RSpec.describe Parent::SendCalendlyReminderService do
  include ActiveJob::TestHelper

  let(:sunday) { Date.new(2026, 3, 8) } # a Sunday
  let(:next_monday) { sunday + 1.day }
  let(:beta_test_email) { 'beta@example.com' }

  let(:supporter) do
    FactoryBot.create(:admin_user,
      user_role: 'caller',
      email: beta_test_email,
      can_send_automatic_sms: true,
      aircall_number_id: 12345,
      aircall_phone_number: '+33123456789',
      calendly_user_uri: 'https://api.calendly.com/users/abc123'
    )
  end

  let(:group) do
    FactoryBot.create(:group,
      started_at: next_monday - 4.weeks,
      type_of_support: 'with_calls',
      call1_start_date: next_monday,
      call1_end_date: next_monday + 2.weeks
    )
  end

  let(:parent) do
    FactoryBot.create(:parent,
      calendly_booking_urls: { 'call1' => 'https://calendly.com/d/abc-def/appel?utm_source=1001mots' }
    )
  end

  let(:child) do
    FactoryBot.create(:child,
      parent1: parent,
      group: group,
      group_status: 'active',
      should_contact_parent1: true
    )
  end

  let(:child_support) { child.child_support.tap { |cs| cs.update!(supporter: supporter, call1_status: nil) } }

  subject { described_class.new(sunday_date: sunday) }

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

    context 'when a parent is eligible' do
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

      it 'schedules the reminder job at 14h on Sunday (offset by one rate-limit interval)' do
        subject.call
        expected_time = ActiveSupport::TimeZone['Europe/Paris'].parse("#{sunday.strftime('%Y-%m-%d')} 14:00") + Parent::SendCalendlyReminderService::AIRCALL_RATE_LIMIT_INTERVAL
        expect(Aircall::SendCalendlyReminderJob).to have_been_enqueued.at(expected_time)
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
        (max_per_hour).times.map do
          p = FactoryBot.create(:parent,
            calendly_booking_urls: { 'call1' => 'https://calendly.com/d/abc/appel' }
          )
          c = FactoryBot.create(:child, parent1: p, group: group, group_status: 'active', should_contact_parent1: true)
          c.child_support.update!(supporter: supporter, call1_status: nil)
          p
        end
      end

      before { extra_parents }

      it 'puts the first batch in the 14h slot and overflow in the 15h slot' do
        subject.call
        expected_14h = ActiveSupport::TimeZone['Europe/Paris'].parse("#{sunday.strftime('%Y-%m-%d')} 14:00").to_i
        expected_15h = ActiveSupport::TimeZone['Europe/Paris'].parse("#{sunday.strftime('%Y-%m-%d')} 15:00").to_i
        jobs_in_14h_slot = enqueued_jobs.select { |j| j[:at].to_i >= expected_14h && j[:at].to_i < expected_15h }
        jobs_in_15h_slot = enqueued_jobs.select { |j| j[:at].to_i >= expected_15h && j[:at].to_i < expected_15h + 3600 }
        expect(jobs_in_14h_slot.size).to eq(max_per_hour)
        expect(jobs_in_15h_slot.size).to eq(1) # the original parent
      end

      it 'staggers the jobs within the 14h slot by AIRCALL_RATE_LIMIT_INTERVAL' do
        subject.call
        expected_14h = ActiveSupport::TimeZone['Europe/Paris'].parse("#{sunday.strftime('%Y-%m-%d')} 14:00").to_i
        interval = Parent::SendCalendlyReminderService::AIRCALL_RATE_LIMIT_INTERVAL.to_i
        timestamps_in_14h_slot = enqueued_jobs
          .map { |j| j[:at].to_i }
          .select { |t| t >= expected_14h && t < expected_14h + 3600 }
          .sort
        expected_timestamps = (1..max_per_hour).map { |i| expected_14h + i * interval }
        expect(timestamps_in_14h_slot).to eq(expected_timestamps)
      end
    end

    context 'with two supporters, each with their own batch' do
      let(:second_supporter_email) { 'beta2@example.com' }
      let(:second_supporter) do
        FactoryBot.create(:admin_user,
          user_role: 'caller',
          email: second_supporter_email,
          can_send_automatic_sms: true,
          aircall_number_id: 99999,
          aircall_phone_number: '+33987654321',
          calendly_user_uri: 'https://api.calendly.com/users/def456'
        )
      end
      let(:second_parent) do
        FactoryBot.create(:parent,
          calendly_booking_urls: { 'call1' => 'https://calendly.com/d/xyz/appel' }
        )
      end
      let(:second_child) do
        FactoryBot.create(:child, parent1: second_parent, group: group, group_status: 'active', should_contact_parent1: true)
      end

      before do
        stub_const('ENV', ENV.to_h.merge('BETA_TEST_CALLERS_EMAIL' => "#{beta_test_email} #{second_supporter_email}"))
        second_child.child_support.update!(supporter: second_supporter, call1_status: nil)
      end

      it 'schedules one job per supporter in the 14h slot, staggered' do
        subject.call
        expected_14h = ActiveSupport::TimeZone['Europe/Paris'].parse("#{sunday.strftime('%Y-%m-%d')} 14:00").to_i
        expected_15h = ActiveSupport::TimeZone['Europe/Paris'].parse("#{sunday.strftime('%Y-%m-%d')} 15:00").to_i
        interval = Parent::SendCalendlyReminderService::AIRCALL_RATE_LIMIT_INTERVAL.to_i
        timestamps_in_14h_slot = enqueued_jobs
          .map { |j| j[:at].to_i }
          .select { |t| t >= expected_14h && t < expected_15h }
          .sort
        expect(timestamps_in_14h_slot).to eq([expected_14h + 2 * interval, expected_14h + 3 * interval])
      end
    end
  end
end