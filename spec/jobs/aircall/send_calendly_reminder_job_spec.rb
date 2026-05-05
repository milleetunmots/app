require 'rails_helper'

RSpec.describe Aircall::SendCalendlyReminderJob do
  include ActiveJob::TestHelper

  let(:supporter) do
    FactoryBot.create(:admin_user,
      user_role: 'caller',
      email: 'caller@mail.com',
      can_send_automatic_sms: true,
      aircall_number_id: 12345,
      aircall_phone_number: '+33123456789',
      calendly_user_uri: 'https://api.calendly.com/users/abc123'
    )
  end

  let(:next_monday) { Date.new(2026, 3, 9) }

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
      calendly_booking_urls: { 'call1' => 'https://calendly.com/d/abc/appel' }
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
  let(:calendly_url) { 'https://calendly.com/d/abc/appel' }

  before do
    ActiveJob::Base.queue_adapter = :test
    child_support
  end

  subject { described_class.new.perform(child_support.id, 1, parent.id, calendly_url) }

  context 'when no RDV has been booked and call status is empty' do
    it 'creates an Event with the aircall provider' do
      expect { subject }.to change(Event, :count).by(1)
      expect(Event.last.message_provider).to eq('aircall')
    end

    it 'enqueues Aircall::SendMessageJob without delay' do
      expect { subject }.to have_enqueued_job(Aircall::SendMessageJob)
    end

    it 'includes the child name and calendly url in the body' do
      subject
      expect(Event.last.body).to include(child.first_name)
      expect(Event.last.body).to include(calendly_url)
    end

    it 'updates calendly_last_booking_dates on the parent' do
      subject
      parent.reload
      expect(parent.calendly_last_booking_dates['call1']).to be_present
    end
  end

  context 'when a RDV is already scheduled for that call session' do
    before do
      FactoryBot.create(:scheduled_call, parent: parent, child_support: child_support, call_session: 1, status: 'scheduled')
    end

    it 'does not create an Event' do
      expect { subject }.not_to change(Event, :count)
    end

    it 'does not enqueue Aircall::SendMessageJob' do
      expect { subject }.not_to have_enqueued_job(Aircall::SendMessageJob)
    end
  end

  context 'when a RDV is canceled' do
    before do
      FactoryBot.create(:scheduled_call, :canceled, parent: parent, child_support: child_support, call_session: 1)
    end

    it 'still sends the reminder' do
      expect { subject }.to have_enqueued_job(Aircall::SendMessageJob)
    end
  end

  context 'when call status is already filled' do
    before { child_support.update!(call1_status: ChildSupport.human_attribute_name('call_status.1_ok')) }

    it 'does not enqueue Aircall::SendMessageJob' do
      expect { subject }.not_to have_enqueued_job(Aircall::SendMessageJob)
    end
  end

  context 'when supporter has no aircall_number_id' do
    before { supporter.update!(aircall_number_id: nil) }

    it 'does not enqueue Aircall::SendMessageJob' do
      expect { subject }.not_to have_enqueued_job(Aircall::SendMessageJob)
    end
  end
end
