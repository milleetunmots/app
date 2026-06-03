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
require "rails_helper"

RSpec.describe CallSessionDateOverride, type: :model do
  let(:group) { FactoryBot.create(:group) }
  let(:admin_user) { FactoryBot.create(:admin_user) }

  subject { FactoryBot.create(:call_session_date_override, admin_user: admin_user, group: group) }

  describe "Validations" do
    context "succeed" do
      it "with valid attributes" do
        expect(FactoryBot.build(:call_session_date_override, admin_user: admin_user, group: group)).to be_valid
      end

      it "when start_date equals end_date" do
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

    context "fail" do
      it "without start_date" do
        override = FactoryBot.build(
          :call_session_date_override,
          admin_user: admin_user,
          group: group,
          start_date: nil
        )
        expect(override).not_to be_valid
      end

      it "without end_date" do
        override = FactoryBot.build(
          :call_session_date_override,
          admin_user: admin_user,
          group: group,
          end_date: nil
        )
        expect(override).not_to be_valid
      end

      it "when start_date is after end_date" do
        override = FactoryBot.build(
          :call_session_date_override,
          admin_user: admin_user,
          group: group,
          call_session: 0,
          start_date: group.call0_end_date - 1.day,
          end_date: group.call0_start_date + 1.day
        )
        expect(override).not_to be_valid
      end
    end
  end

  describe "#call_session" do
    it "is required" do
      subject.call_session = nil

      expect(subject).not_to be_valid
    end

    it "is included in CALL_SESSIONS" do
      subject.call_session = -1
      expect(subject).not_to be_valid

      subject.call_session = 4
      expect(subject).not_to be_valid
    end

    it "is valid for each value in CALL_SESSIONS" do
      CallSessionDateOverride::CALL_SESSIONS.each do |i|
        override = FactoryBot.build(
          :call_session_date_override,
          admin_user: admin_user,
          group: group,
          call_session: i
        )
        expect(override).to be_valid
      end
    end

    it "is unique scoped to admin_user and group" do
      duplicate = FactoryBot.build(
        :call_session_date_override,
        admin_user: subject.admin_user,
        group: subject.group,
        call_session: subject.call_session
      )

      expect(duplicate).not_to be_valid
    end
  end

  describe "#start_date" do
    it "cannot be before the group call session start_date" do
      override = FactoryBot.build(
        :call_session_date_override,
        admin_user: admin_user,
        group: group,
        call_session: 1,
        start_date: group.call1_start_date - 1.day,
        end_date: group.call1_end_date - 1.day
      )

      expect(override).not_to be_valid
    end
  end

  describe "#end_date" do
    it "cannot be after the group call session end_date" do
      override = FactoryBot.build(
        :call_session_date_override,
        admin_user: admin_user,
        group: group,
        call_session: 1,
        start_date: group.call1_start_date + 1.day,
        end_date: group.call1_end_date + 1.day
      )

      expect(override).not_to be_valid
    end
  end
end