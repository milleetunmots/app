# == Schema Information
#
# Table name: groups
#
#  id           :bigint           not null, primary key
#  discarded_at :datetime
#  ended_at     :date
#  name         :string
#  started_at   :date
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_groups_on_discarded_at  (discarded_at)
#  index_groups_on_ended_at      (ended_at)
#  index_groups_on_started_at    (started_at)
#

require 'rails_helper'

RSpec.describe Group, type: :model do
  before(:each) do
    @group_ended = FactoryBot.create(:group, ended_at: Date.yesterday)
    @group_not_ended = FactoryBot.create(:group, ended_at: Date.tomorrow)
  end

  describe "Validations" do
    context "succeed" do
      it "if the group have a name " do
        expect(FactoryBot.build_stubbed(:group)).to be_valid
      end
    end

    context "fail" do
      it "if the group doesn't have a name" do
        expect(FactoryBot.build_stubbed(:group, name: nil)).to be_invalid
      end
    end
  end

  describe "#not_ended" do
    context "returns" do
      it "groups not ended" do
        expect(Group.not_ended).to eq [@group_not_ended]
      end
    end
  end

  describe "#ended" do
    context "returns" do
      it "groups ended" do
        expect(Group.ended).to eq [@group_ended]
      end
    end
  end

  describe ".is_ended? returns" do
    context "true" do
      it "if the group is ended" do
        expect(@group_ended.is_ended?).to eq TRUE
      end
    end

    context "false" do
      it "if the group isn't ended" do
        expect(@group_not_ended.is_ended?).to eq FALSE
      end
    end
  end

  describe ".is_not_ended? returns" do
    context "true" do
      it "if the group is not ended" do
        expect(@group_ended.is_not_ended?).to eq FALSE
      end
    end

    context "false" do
      it "if the group is ended" do
        expect(@group_not_ended.is_not_ended?).to eq TRUE
      end
    end
  end
end
