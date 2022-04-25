# == Schema Information
#
# Table name: families
#
#  id               :bigint           not null, primary key
#  discarded_at     :datetime
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  child_support_id :bigint
#  parent1_id       :bigint           not null
#  parent2_id       :bigint
#
# Indexes
#
#  index_families_on_child_support_id  (child_support_id)
#  index_families_on_parent1_id        (parent1_id)
#  index_families_on_parent2_id        (parent2_id)
#
# Foreign Keys
#
#  fk_rails_...  (parent1_id => parents.id)
#  fk_rails_...  (parent2_id => parents.id)
#
require 'rails_helper'

RSpec.describe Family, type: :model do
  subject { FactoryBot.create(:family) }

  describe "Validations" do
    context "succeed" do
      it "if minimal attributes are present" do
        expect(subject).to be_valid
      end
    end

    context "fail" do
      it "if parent1 isn't provided" do
        subject.parent1 = nil
        expect(subject).to_not be_valid
      end
    end
  end
end
