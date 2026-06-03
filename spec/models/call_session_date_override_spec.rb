# == Schema Information
#
# Table name: call_session_date_overrides
#
#  id            :bigint           not null, primary key
#  call_session  :integer          not null
#  end_date      :date             not null
#  start_date    :date             not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  admin_user_id :bigint           not null
#  group_id      :bigint           not null
#
# Indexes
#
#  index_call_session_date_overrides_on_admin_user_id  (admin_user_id)
#  index_call_session_date_overrides_on_group_id       (group_id)
#  index_call_session_date_overrides_on_trio           (admin_user_id,group_id,call_session) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (admin_user_id => admin_users.id)
#  fk_rails_...  (group_id => groups.id)
#
require 'rails_helper'

RSpec.describe CallSessionDateOverride, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:admin_user) }
    it { is_expected.to belong_to(:group) }
  end

  describe 'validations' do
    let(:group) { FactoryBot.create(:group) }
    let(:admin_user) { FactoryBot.create(:admin_user) }

    it 'is valid with valid attributes' do
      override = FactoryBot.build(:call_session_date_override, admin_user: admin_user, group: group)
      expect(override).to be_valid
    end

    describe 'call_session' do
      it 'is invalid without a call_session' do
        override = FactoryBot.build(:call_session_date_override, call_session: nil)
        expect(override).not_to be_valid
        expect(override.errors[:call_session]).to be_present
      end

      it 'is invalid when call_session is below 0' do
        override = FactoryBot.build(:call_session_date_override, call_session: -1)
        expect(override).not_to be_valid
        expect(override.errors[:call_session]).to be_present
      end

      it 'is invalid when call_session is above 3' do
        override = FactoryBot.build(:call_session_date_override, call_session: 4)
        expect(override).not_to be_valid
        expect(override.errors[:call_session]).to be_present
      end

      it 'is valid for each value in 0..3' do
        (0..3).each do |i|
          override = FactoryBot.build(
            :call_session_date_override,
            admin_user: admin_user,
            group: group,
            call_session: i
          )
          expect(override).to be_valid
        end
      end

      it 'is invalid when the trio (admin_user, group, call_session) already exists' do
        existing = FactoryBot.create(:call_session_date_override)
        duplicate = FactoryBot.build(
          :call_session_date_override,
          admin_user: existing.admin_user,
          group: existing.group,
          call_session: existing.call_session
        )
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:call_session]).to be_present
      end
    end

    describe 'dates presence' do
      it 'is invalid without start_date' do
        override = FactoryBot.build(:call_session_date_override, start_date: nil)
        expect(override).not_to be_valid
        expect(override.errors[:start_date]).to be_present
      end

      it 'is invalid without end_date' do
        override = FactoryBot.build(:call_session_date_override, end_date: nil)
        expect(override).not_to be_valid
        expect(override.errors[:end_date]).to be_present
      end
    end

    describe 'start_date <= end_date' do
      it 'is invalid when start_date is after end_date' do
        override = FactoryBot.build(
          :call_session_date_override,
          admin_user: admin_user,
          group: group,
          call_session: 0,
          start_date: group.call0_end_date - 1.day,
          end_date: group.call0_start_date + 1.day
        )
        expect(override).not_to be_valid
        expect(override.errors[:start_date]).to be_present
      end

      it 'is valid when start_date equals end_date' do
        same_day = group.call0_start_date + 2.days
        override = FactoryBot.build(
          :call_session_date_override,
          admin_user: admin_user,
          group: group,
          call_session: 0,
          start_date: same_day,
          end_date: same_day
        )
        expect(override).to be_valid
      end
    end

    describe 'dates within group call session window' do
      it 'is invalid when start_date is equal to the group call session start_date' do
        override = FactoryBot.build(
          :call_session_date_override,
          admin_user: admin_user,
          group: group,
          call_session: 1,
          start_date: group.call1_start_date,
          end_date: group.call1_end_date - 1.day
        )
        expect(override).not_to be_valid
        expect(override.errors[:start_date]).to be_present
      end

      it 'is invalid when start_date is before the group call session start_date' do
        override = FactoryBot.build(
          :call_session_date_override,
          admin_user: admin_user,
          group: group,
          call_session: 1,
          start_date: group.call1_start_date - 1.day,
          end_date: group.call1_end_date - 1.day
        )
        expect(override).not_to be_valid
        expect(override.errors[:start_date]).to be_present
      end

      it 'is invalid when end_date is equal to the group call session end_date' do
        override = FactoryBot.build(
          :call_session_date_override,
          admin_user: admin_user,
          group: group,
          call_session: 1,
          start_date: group.call1_start_date + 1.day,
          end_date: group.call1_end_date
        )
        expect(override).not_to be_valid
        expect(override.errors[:end_date]).to be_present
      end

      it 'is invalid when end_date is after the group call session end_date' do
        override = FactoryBot.build(
          :call_session_date_override,
          admin_user: admin_user,
          group: group,
          call_session: 1,
          start_date: group.call1_start_date + 1.day,
          end_date: group.call1_end_date + 1.day
        )
        expect(override).not_to be_valid
        expect(override.errors[:end_date]).to be_present
      end
    end
  end
end
