# == Schema Information
#
# Table name: support_modules
#
#  id           :bigint           not null, primary key
#  discarded_at :datetime
#  name         :string
#  start_at     :date
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_support_modules_on_discarded_at  (discarded_at)
#

require "rails_helper"

RSpec.describe SupportModule, type: :model do
  describe "Validations" do
    context "succeed" do
      it "if minimal attributes are present" do
        expect(FactoryBot.build(:support_module)).to be_valid
      end
    end

    context "fail" do
      it "if the support module doesn't have name" do
        expect(FactoryBot.build(:support_module, name: nil)).not_to be_valid
      end
    end
  end

  describe ".duplicate" do
    context "returns" do
      it "new support module with the same attributes" do
        support_module = FactoryBot.create(:support_module)
        new_support_module = support_module.duplicate
        expect(new_support_module.name).to eq "Copie de #{support_module.name}"
        expect(new_support_module.tag_list).to eq support_module.tag_list
        expect(new_support_module.support_module_weeks).to eq support_module.support_module_weeks
      end
    end
  end
end
