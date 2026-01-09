# == Schema Information
#
# Table name: scheduled_calls
#
#  id                   :bigint           not null, primary key
#  calendly_event_uri   :string           not null
#  calendly_invitee_uri :string
#  call_session         :integer
#  canceled_at          :datetime
#  cancellation_reason  :text
#  duration_minutes     :integer
#  event_type_name      :string
#  event_type_uri       :string
#  invitee_comment      :text
#  invitee_email        :string
#  invitee_name         :string
#  raw_payload          :jsonb
#  scheduled_at         :datetime
#  status               :string           default("scheduled"), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  admin_user_id        :bigint
#  child_support_id     :bigint
#  parent_id            :bigint
#
# Indexes
#
#  index_scheduled_calls_on_admin_user_id       (admin_user_id)
#  index_scheduled_calls_on_calendly_event_uri  (calendly_event_uri) UNIQUE
#  index_scheduled_calls_on_child_support_id    (child_support_id)
#  index_scheduled_calls_on_parent_id           (parent_id)
#  index_scheduled_calls_on_scheduled_at        (scheduled_at)
#  index_scheduled_calls_on_status              (status)
#
# Foreign Keys
#
#  fk_rails_...  (admin_user_id => admin_users.id)
#  fk_rails_...  (child_support_id => child_supports.id)
#  fk_rails_...  (parent_id => parents.id)
#
require 'rails_helper'

RSpec.describe ScheduledCall, type: :model do
  let(:parent) { FactoryBot.create(:parent) }
  let(:child) { FactoryBot.create(:child, parent1: parent) }
  let(:child_support) { child.child_support }
  let(:admin_user) { FactoryBot.create(:admin_user) }

  describe 'validations' do
    it 'is valid with valid attributes' do
      scheduled_call = ScheduledCall.new(
        calendly_event_uri: 'https://api.calendly.com/scheduled_events/abc123',
        status: 'scheduled'
      )
      expect(scheduled_call).to be_valid
    end

    it 'is invalid without calendly_event_uri' do
      scheduled_call = ScheduledCall.new(status: 'scheduled')
      expect(scheduled_call).not_to be_valid
      expect(scheduled_call.errors[:calendly_event_uri]).to be_present
    end

    it 'is invalid with duplicate calendly_event_uri' do
      ScheduledCall.create!(
        calendly_event_uri: 'https://api.calendly.com/scheduled_events/abc123',
        status: 'scheduled'
      )
      duplicate = ScheduledCall.new(
        calendly_event_uri: 'https://api.calendly.com/scheduled_events/abc123',
        status: 'scheduled'
      )
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:calendly_event_uri]).to be_present
    end

    it 'is invalid with invalid status' do
      scheduled_call = ScheduledCall.new(
        calendly_event_uri: 'https://api.calendly.com/scheduled_events/abc123',
        status: 'invalid_status'
      )
      expect(scheduled_call).not_to be_valid
      expect(scheduled_call.errors[:status]).to be_present
    end
  end

  describe 'associations' do
    it 'belongs to admin_user' do
      scheduled_call = ScheduledCall.create!(
        calendly_event_uri: 'https://api.calendly.com/scheduled_events/abc123',
        admin_user: admin_user
      )
      expect(scheduled_call.admin_user).to eq(admin_user)
    end

    it 'belongs to child_support' do
      scheduled_call = ScheduledCall.create!(
        calendly_event_uri: 'https://api.calendly.com/scheduled_events/abc123',
        child_support: child_support
      )
      expect(scheduled_call.child_support).to eq(child_support)
    end

    it 'belongs to parent' do
      scheduled_call = ScheduledCall.create!(
        calendly_event_uri: 'https://api.calendly.com/scheduled_events/abc123',
        parent: parent
      )
      expect(scheduled_call.parent).to eq(parent)
    end
  end

  describe 'scopes' do
    let!(:scheduled) do
      ScheduledCall.create!(
        calendly_event_uri: 'https://api.calendly.com/scheduled_events/scheduled1',
        status: 'scheduled',
        scheduled_at: 1.day.from_now
      )
    end

    let!(:canceled) do
      ScheduledCall.create!(
        calendly_event_uri: 'https://api.calendly.com/scheduled_events/canceled1',
        status: 'canceled',
        scheduled_at: 1.day.from_now
      )
    end

    let!(:past) do
      ScheduledCall.create!(
        calendly_event_uri: 'https://api.calendly.com/scheduled_events/past1',
        status: 'scheduled',
        scheduled_at: 1.day.ago
      )
    end

    describe '.scheduled' do
      it 'returns only scheduled calls' do
        expect(ScheduledCall.scheduled).to include(scheduled, past)
        expect(ScheduledCall.scheduled).not_to include(canceled)
      end
    end

    describe '.canceled' do
      it 'returns only canceled calls' do
        expect(ScheduledCall.canceled).to include(canceled)
        expect(ScheduledCall.canceled).not_to include(scheduled, past)
      end
    end

    describe '.upcoming' do
      it 'returns only future scheduled calls' do
        expect(ScheduledCall.upcoming).to include(scheduled)
        expect(ScheduledCall.upcoming).not_to include(past, canceled)
      end
    end

    describe '.past' do
      it 'returns only past calls' do
        expect(ScheduledCall.past).to include(past)
        expect(ScheduledCall.past).not_to include(scheduled)
      end
    end
  end

  describe '#scheduled?' do
    it 'returns true when status is scheduled' do
      scheduled_call = ScheduledCall.new(status: 'scheduled')
      expect(scheduled_call.scheduled?).to be true
    end

    it 'returns false when status is not scheduled' do
      scheduled_call = ScheduledCall.new(status: 'canceled')
      expect(scheduled_call.scheduled?).to be false
    end
  end

  describe '#canceled?' do
    it 'returns true when status is canceled' do
      scheduled_call = ScheduledCall.new(status: 'canceled')
      expect(scheduled_call.canceled?).to be true
    end

    it 'returns false when status is not canceled' do
      scheduled_call = ScheduledCall.new(status: 'scheduled')
      expect(scheduled_call.canceled?).to be false
    end
  end

  describe '#cancel!' do
    let(:scheduled_call) do
      ScheduledCall.create!(
        calendly_event_uri: 'https://api.calendly.com/scheduled_events/abc123',
        status: 'scheduled'
      )
    end

    it 'updates status to canceled' do
      scheduled_call.cancel!
      expect(scheduled_call.reload.status).to eq('canceled')
    end

    it 'sets canceled_at' do
      scheduled_call.cancel!
      expect(scheduled_call.reload.canceled_at).to be_within(1.second).of(Time.current)
    end

    it 'accepts a custom reason' do
      scheduled_call.cancel!(reason: 'Family emergency')
      expect(scheduled_call.reload.cancellation_reason).to eq('Family emergency')
    end

    it 'accepts a custom canceled_at' do
      custom_time = 2.hours.ago
      scheduled_call.cancel!(canceled_at: custom_time)
      expect(scheduled_call.reload.canceled_at).to eq(custom_time)
    end
  end
end
