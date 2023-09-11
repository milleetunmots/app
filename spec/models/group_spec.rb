# == Schema Information
#
# Table name: groups
#
#  id                        :bigint           not null, primary key
#  discarded_at              :datetime
#  ended_at                  :date
#  is_programmed             :boolean          default(FALSE), not null
#  name                      :string
#  started_at                :date
#  support_module_programmed :integer          default(0)
#  support_modules_count     :integer          default(0), not null
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#
# Indexes
#
#  index_groups_on_discarded_at  (discarded_at)
#  index_groups_on_ended_at      (ended_at)
#  index_groups_on_started_at    (started_at)
#

require "rails_helper"

RSpec.describe Group, type: :model do
  before(:each) do
    @group_ended1 = FactoryBot.create(:group, ended_at: Date.yesterday)
    @group_ended2 = FactoryBot.create(:group, ended_at: Date.yesterday)
    @group_not_ended1 = FactoryBot.create(:group, ended_at: Date.tomorrow)
    @group_not_ended2 = FactoryBot.create(:group, ended_at: Date.tomorrow)
  end

  describe "Validations" do
    context "succeed" do
      it "if the group have a name " do
        expect(FactoryBot.build_stubbed(:group)).to be_valid
      end
    end

    context "fail" do
      it "if the group doesn't have a name" do
        expect(FactoryBot.build_stubbed(:group, name: nil)).not_to be_valid
      end
    end
  end

  describe "#not_ended" do
    context "returns" do
      it "groups not ended" do
        expect(Group.not_ended).to eq [@group_not_ended1, @group_not_ended2]
      end
    end
  end

  describe "#ended" do
    context "returns" do
      it "groups ended" do
        expect(Group.ended).to eq [@group_ended1, @group_ended2]
      end
    end
  end

  describe ".is_ended? returns" do
    context "true" do
      it "if the group is ended" do
        expect(@group_ended1.is_ended?).to be_truthy
        expect(@group_ended2.is_ended?).to be_truthy
      end
    end

    context "false" do
      it "if the group isn't ended" do
        expect(@group_not_ended1.is_ended?).not_to be be_truthy
        expect(@group_not_ended2.is_ended?).not_to be be_truthy
      end
    end
  end

  describe ".is_not_ended? returns" do
    context "true" do
      it "if the group is not ended" do
        expect(@group_ended1.is_not_ended?).not_to be_truthy
        expect(@group_ended2.is_not_ended?).not_to be_truthy
      end
    end

    context "false" do
      it "if the group is ended" do
        expect(@group_not_ended1.is_not_ended?).to be_truthy
        expect(@group_not_ended2.is_not_ended?).to be_truthy
      end
    end
  end
end
