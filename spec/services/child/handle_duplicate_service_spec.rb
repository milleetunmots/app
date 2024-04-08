require 'rails_helper'

RSpec.describe Child::HandleDuplicateService do
  subject { Child::HandleDuplicateService.new }
  context "when many parents with the same phone number have differents children" do
    let!(:first_parent) { FactoryBot.create(:parent, phone_number: '0755802002')}
    let!(:second_parent) { FactoryBot.create(:parent, phone_number: '0755802002')}
    let!(:first_child) { FactoryBot.create(:child, parent1: first_parent) }
    let!(:second_child) { FactoryBot.create(:child, parent1: second_parent) }
    let!(:third_child) { FactoryBot.create(:child, parent1: second_parent) }
    let(:group) {FactoryBot.create(:group) }

    it "put all the children in the same sibling group" do
      first_child_support_id = first_child.child_support_id
      first_parent_id = first_parent.id

      subject.call

      expect(second_child.reload.child_support_id).to eq(first_child_support_id)
      expect(second_child.reload.parent1_id).to eq(first_parent_id)
      expect(third_child.reload.child_support_id).to eq(first_child_support_id)
      expect(third_child.reload.parent1_id).to eq(first_parent_id)
      expect(second_parent.reload.discarded?).to eq(true)
    end

    it "if a child is in active group, add the others children to his siblings" do
      group.started_at = 2.months.ago.beginning_of_week
      group.save!
      second_child.group_id = group.id
      second_child.group_status = 'active'
      second_child.save!
      second_child_support_id = second_child.child_support_id
      second_parent_id = second_parent.id

      subject.call

      expect(first_child.reload.child_support_id).to eq(second_child_support_id)
      expect(first_child.reload.parent1_id).to eq(second_parent_id)
      expect(first_parent.reload.discarded?).to eq(true)
    end
  end

  context "when many parents with the same phone number have same children" do
    let!(:first_parent) { FactoryBot.create(:parent, phone_number: '0755800000')}
    let!(:second_parent) { FactoryBot.create(:parent, phone_number: '0755800000')}
    let!(:first_child) { FactoryBot.create(:child, first_name: 'preNom', last_name: 'nOm', parent1: first_parent) }
    let!(:second_child) { FactoryBot.create(:child, first_name: 'Prenom ', last_name: ' Nom', birthdate: first_child.birthdate, parent1: second_parent) }

    it "discard the last children and their parents" do
      subject.call
      expect(second_child.reload.discarded?).to eq(true)
      expect(first_child.reload.discarded?).to eq(false)
      expect(second_parent.reload.discarded?).to eq(true)
      expect(first_parent.reload.discarded?).to eq(false)
    end
  end

  context "when many children with same firstname, lastname and phone number have differents parents" do
    let!(:first_parent) { FactoryBot.create(:parent, phone_number: '0755800000')}
    let!(:second_parent) { FactoryBot.create(:parent, phone_number: '0755800001')}
    let!(:first_child) { FactoryBot.create(:child, first_name: 'preNom', last_name: 'nOm', parent1: first_parent) }
    let!(:second_child) { FactoryBot.create(:child, first_name: 'Prenom ', last_name: ' Nom', birthdate: first_child.birthdate, parent1: second_parent) }

    it "link the parents" do
      subject.call
      expect(first_child.reload.parent1_id).to eq first_parent.id
      expect(first_child.reload.parent2_id).to eq second_parent.id
      expect(second_child.reload.discarded?).to eq(true)
    end
  end
end
