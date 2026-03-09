require 'rails_helper'

RSpec.describe Parent::SendCalendlyReminderService do
  include ActiveJob::TestHelper
  let(:sunday) { Date.new(2026, 3, 8) } # a Sunday
  let(:next_monday) { sunday + 1.day }

  let(:supporter) do
    FactoryBot.create(:admin_user,
      user_role: 'caller',
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
    child_support # trigger setup
  end

  describe '#initialize' do
    it 'initializes with no errors' do
      expect(subject.errors).to eq([])
    end
  end

  describe '#call' do
    context 'when a parent is eligible' do
      it 'returns no errors' do
        result = subject.call
        expect(result.errors).to be_empty
      end

      it 'creates an Event for the parent' do
        expect { subject.call }.to change(Event, :count).by(1)
      end

      it 'schedules an Aircall::SendMessageJob' do
        expect { subject.call }.to have_enqueued_job(Aircall::SendMessageJob)
      end

      it 'uses the supporter aircall_number_id' do
        subject.call
        event = Event.last
        expect(event.message_provider).to eq('aircall')
      end

      it 'includes the child name in the message' do
        subject.call
        event = Event.last
        expect(event.body).to include(child.first_name)
      end

      it 'includes the calendly link in the message' do
        subject.call
        event = Event.last
        expect(event.body).to include('https://calendly.com/d/abc-def/appel')
      end

      it 'schedules the job at 14h on Sunday' do
        subject.call
        expected_time = ActiveSupport::TimeZone['Europe/Paris'].parse("#{sunday.strftime('%Y-%m-%d')} 14:00")
        expect(Aircall::SendMessageJob).to have_been_enqueued.at(expected_time)
      end
    end

    context 'when the parent already has a scheduled call for the session' do
      before do
        FactoryBot.create(:scheduled_call,
          parent: parent,
          call_session: 1,
          status: 'scheduled'
        )
      end

      it 'does not send the reminder' do
        expect { subject.call }.not_to have_enqueued_job(Aircall::SendMessageJob)
      end
    end

    context 'when the parent has a canceled scheduled call' do
      before do
        FactoryBot.create(:scheduled_call, :canceled, parent: parent, call_session: 1)
      end

      it 'sends the reminder (canceled does not count as booked)' do
        expect { subject.call }.to have_enqueued_job(Aircall::SendMessageJob)
      end
    end

    context 'when the parent has no calendly booking url for the session' do
      before { parent.update!(calendly_booking_urls: {}) }

      it 'does not send the reminder' do
        expect { subject.call }.not_to have_enqueued_job(Aircall::SendMessageJob)
      end
    end

    context 'when the call status is already filled' do
      before { child_support.update!(call1_status: ChildSupport.human_attribute_name('call_status.1_ok')) }

      it 'does not send the reminder' do
        expect { subject.call }.not_to have_enqueued_job(Aircall::SendMessageJob)
      end
    end

    context 'when the supporter has no aircall_number_id' do
      before { supporter.update!(aircall_number_id: nil) }

      it 'does not send the reminder' do
        expect { subject.call }.not_to have_enqueued_job(Aircall::SendMessageJob)
      end
    end

    context 'with multiple eligible parents batched' do
      let(:parents_with_children) do
        35.times.map do
          p = FactoryBot.create(:parent,
            calendly_booking_urls: { 'call1' => 'https://calendly.com/d/abc/appel' }
          )
          c = FactoryBot.create(:child, parent1: p, group: group, group_status: 'active', should_contact_parent1: true)
          c.child_support.update!(supporter: supporter, call1_status: nil)
          p
        end
      end

      before { parents_with_children }

      it 'splits into batches at different hours' do
        subject.call
        # First 30 at 14h, next 5 (+ original 1) at 15h
        expected_14h = ActiveSupport::TimeZone['Europe/Paris'].parse("#{sunday.strftime('%Y-%m-%d')} 14:00")
        expected_15h = ActiveSupport::TimeZone['Europe/Paris'].parse("#{sunday.strftime('%Y-%m-%d')} 15:00")
        jobs_at_14h = enqueued_jobs.select { |j| j[:at].to_i == expected_14h.to_i }
        jobs_at_15h = enqueued_jobs.select { |j| j[:at].to_i == expected_15h.to_i }
        expect(jobs_at_14h.size).to eq(30)
        expect(jobs_at_15h.size).to be >= 1
      end
    end
  end
end
