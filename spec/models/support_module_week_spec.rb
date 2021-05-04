# == Schema Information
#
# Table name: support_module_weeks
#
#  id                   :bigint           not null, primary key
#  has_been_sent1       :boolean          default(FALSE), not null
#  has_been_sent2       :boolean          default(FALSE), not null
#  has_been_sent3       :boolean          default(FALSE), not null
#  has_been_sent4       :boolean          default(FALSE), not null
#  position             :integer          default(0), not null
#  additional_medium_id :integer
#  medium_id            :bigint
#  support_module_id    :bigint           not null
#
# Indexes
#
#  index_support_module_weeks_on_additional_medium_id  (additional_medium_id)
#  index_support_module_weeks_on_medium_id             (medium_id)
#  index_support_module_weeks_on_position              (position)
#  index_support_module_weeks_on_support_module_id     (support_module_id)
#
# Foreign Keys
#
#  fk_rails_...  (additional_medium_id => media.id)
#

require "rails_helper"

RSpec.describe SupportModuleWeek, type: :model do
  describe "Validations" do
    context "succeed" do
      it "if minimal attributes are present" do
        expect(FactoryBot.build(:support_module_week)).to be_valid
      end
    end

    context "fail" do
      it "if the support module week doesn't position" do
        expect(FactoryBot.build(:support_module_week, position: nil)).not_to be_valid
      end
    end
  end

  describe "#positioned" do
    context "returns" do
      it "support module weeks ordered by position" do
        first_support_module_week = FactoryBot.create(:support_module_week, position: 0)
        second_support_module_week = FactoryBot.create(:support_module_week, position: 1)
        third_support_module_week = FactoryBot.create(:support_module_week, position: 2)
        expect(SupportModuleWeek.positioned).not_to eq [third_support_module_week, first_support_module_week, second_support_module_week]
        expect(SupportModuleWeek.positioned).to eq [first_support_module_week, second_support_module_week, third_support_module_week]
      end
    end
  end
end
