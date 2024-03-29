require 'rails_helper'

RSpec.describe Child::HandleDuplicateService do
  subject { Child::HandleDuplicateService.new }
  context "when many parents with the same phone number have differents children" do
    # let!(:first_parent) { FactoryBot.create(:parent, phone_number: '0755802002')}
    # let!(:second_parent) { FactoryBot.create(:parent, phone_number: '0755802002')}
    # let!(:first_child) { FactoryBot.create(:child, parent1: first_parent) }
    # let!(:second_child) { FactoryBot.create(:child, parent1: second_parent) }

    it "add all children to a first child_support" do
      # p first_child.child_support_id
      # p second_child.child_support_id
      # puts "____________________________________________"
      # subject.call

      # expect(first_child.child_support_id).to eq second_child.child_support_id
    end
  end

  context "when many parents with the same phone number have same children" do
    it "delete the last children" do
    end
  end

  context "when many children with same firstname, lastname and phone number have differents parents" do
    it "link the parents" do
    end
  end
end
