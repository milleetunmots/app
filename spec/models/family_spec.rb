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
  let(:first_parent) { FactoryBot.create(:parent) }
  let(:second_parent) { FactoryBot.create(:parent) }

  let(:first_family) { FactoryBot.create(:family, parent1: first_parent) }
  let(:second_family) { FactoryBot.create(:family, parent1: second_parent) }

  let(:first_child) { FactoryBot.create(:child) }
  let(:second_child) { FactoryBot.create(:child) }

  describe "Validations" do
    context "succeed" do
      it "if minimal attributes are present" do
        expect(first_family).to be_valid
      end
    end

    context "fail" do
      it "if parent1 isn't provided" do
        first_family.parent1 = nil
        expect(first_family).to_not be_valid
      end
    end
  end

  describe "#first_child" do
    context "returns" do
      it "the family's first child" do
        first_child.update! family: first_family
        second_child.update! family: first_family

        expect(first_family.first_child).to eq first_child
      end
    end
  end

  # describe "#parent_events" do
  #   context "returns" do
  #     it "the events of family's parents" do
  #       expect(first_family.parent_events).to match_array [first_event, second_event]
  #       expect(second_family.parent_events).to match_array [third_event]
  #     end
  #   end
  # end

  # describe "#parent_id_in" do
  #   context "returns" do
  #     it "family with a parent's id in parameter" do
  #       expect(Family.parent_id_in(first_parent.id)).to match_array [@first_child, @second_child, @third_child]
  #     end
  #   end
  # end

  describe "#set_land_tags" do
    context "after commit" do
      it "add tag to the family based on postal code" do
        first_parent.update! postal_code: 75018
        second_parent.update! postal_code: 78190

        expect(first_family.tag_list).to match_array ["Paris_18_eme"]
        expect(second_family.tag_list).to match_array ["Trappes"]
      end
    end
  end
end
