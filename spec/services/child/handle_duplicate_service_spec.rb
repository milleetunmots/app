require 'rails_helper'

RSpec.describe Child::HandleDuplicateService do
  subject { Child::HandleDuplicateService.new }
  context "when many parents with the same phone number have differents children" do
    let!(:first_parent) { FactoryBot.create(:parent, phone_number: '0755802002')}
    let!(:second_parent) { FactoryBot.create(:parent, phone_number: '0755802002')}
    let!(:first_child) { FactoryBot.create(:child, parent1: first_parent) }
    let!(:second_child) { FactoryBot.create(:child, parent1: second_parent) }
    let!(:third_child) { FactoryBot.create(:child, parent1: second_parent) }
    let!(:group) { FactoryBot.create(:group, expected_children_number: 0) }

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
      new_parents = [first_child.reload.parent1_id, first_child.reload.parent2_id]
      expect(new_parents).to include first_parent.id, second_parent.id
      expect(second_child.reload.discarded?).to eq(true)
    end
  end

  context "when two children with same firstname, lastname, parent1 and at least one of them don't have parent2" do
    let!(:first_parent) { FactoryBot.create(:parent, phone_number: '0755800000') }
    let!(:second_parent) { FactoryBot.create(:parent, phone_number: '0755800001') }
    let!(:duplicated_parent) { FactoryBot.create(:parent, phone_number: '0755800000') }
    let!(:child_with_parent2) { FactoryBot.create(:child, first_name: 'preNom', last_name: 'nOm', parent1: first_parent, parent2: second_parent) }
    let!(:child_without_parent2) { FactoryBot.create(:child, first_name: 'Prenom ', last_name: ' Nom', birthdate: child_with_parent2.birthdate, parent1: duplicated_parent) }
    let!(:group) { FactoryBot.create(:group, expected_children_number: 0) }

    context "if the two children don't have a group" do
      it "delete the child whithout parent2 and his parent1" do
        subject.call
        expect(child_without_parent2.reload.discarded?).to eq(true)
        expect(duplicated_parent.reload.discarded?).to eq(true)
      end
    end

    context "if the two children are in not active group" do
      it "delete the child whithout parent2 and his parent1" do
        child_with_parent2.update(group: group, group_status: 'active')
        child_without_parent2.update(group: group, group_status: 'active')

        subject.call
        expect(child_without_parent2.reload.discarded?).to eq(true)
        expect(duplicated_parent.reload.discarded?).to eq(true)
      end
    end

    context "if many not_active children have parent2" do
      let!(:duplicated_parent1) { FactoryBot.create(:parent, phone_number: '0755800000') }
      let!(:duplicated_parent2) { FactoryBot.create(:parent, phone_number: '0755800001') }
      let!(:duplicated_child_with_parent2) { FactoryBot.create(:child, first_name: ' Prenom ', last_name: ' Nom', birthdate: child_with_parent2.birthdate, parent1: duplicated_parent1, parent2: duplicated_parent2) }
      it "keep the recent child and delete others" do

        subject.call
        expect(child_with_parent2.reload.discarded?).to eq(true)
        expect(child_without_parent2.reload.discarded?).to eq(true)
        expect(first_parent.reload.discarded?).to eq(true)
      end
    end

    context "if a child without parent2 is active" do
      let!(:duplicated_parent1) { FactoryBot.create(:parent, phone_number: '0755800000') }
      let!(:duplicated_parent2) { FactoryBot.create(:parent, phone_number: '0755800001') }
      let!(:duplicated_child_with_parent2) { FactoryBot.create(:child, first_name: ' Prenom ', last_name: ' Nom', birthdate: child_with_parent2.birthdate, parent1: duplicated_parent1, parent2: duplicated_parent2) }
      it "add it parent2 and delete children without group" do
        group.update(started_at: Time.zone.now.prev_occurring(:monday), support_module_programmed: 1)
        child_without_parent2.update(group: group, group_status: 'active')


        subject.call
        expect(child_with_parent2.reload.discarded?).to eq(true)
        expect(first_parent.reload.discarded?).to eq(true)
        expect(child_without_parent2.reload.parent2).to be_present
      end
    end
  end

  context "when two children with same firstname, lastname, parent1 and parent2" do
    let!(:first_parent) { FactoryBot.create(:parent, phone_number: '0755800000') }
    let!(:second_parent) { FactoryBot.create(:parent, phone_number: '0755800001') }
    let!(:duplicated_first_parent) { FactoryBot.create(:parent, phone_number: '0755800000') }
    let!(:duplicated_second_parent) { FactoryBot.create(:parent, phone_number: '0755800001') }
    let!(:first_child) { FactoryBot.create(:child, first_name: 'preNom', last_name: 'nOm', parent1: first_parent, parent2: second_parent) }
    let!(:duplicated_child) { FactoryBot.create(:child, first_name: 'Prenom ', last_name: ' Nom', birthdate: first_child.birthdate, parent1: duplicated_first_parent, parent2: duplicated_second_parent) }

    context "if the two children don't have a group" do
      it "delete the recent child, his parent1, parent2 and his child_support" do
        subject.call
        expect(duplicated_child.reload.discarded?).to eq(true)
        expect(duplicated_first_parent.reload.discarded?).to eq(true)
        expect(duplicated_second_parent.reload.discarded?).to eq(true)
        expect(duplicated_child.child_support.reload.discarded?).to eq(true)
      end
    end

    context "if at least one child is in started group" do
      let!(:group) { FactoryBot.create(:group, expected_children_number: 0) }
      it "keep children in a started group and delete others" do
        group.update(started_at: Time.zone.now.prev_occurring(:monday), support_module_programmed: 1)
        first_child.update(group: group, group_status: 'active')

        subject.call
        expect(duplicated_child.reload.discarded?).to eq(true)
        expect(duplicated_child.child_support.reload.discarded?).to eq(true)
        expect(duplicated_first_parent.reload.discarded?).to eq(true)
        expect(duplicated_second_parent.reload.discarded?).to eq(true)
      end
    end
  end

  context "when there are the same parents and differents children"do
    let!(:first_parent1) { FactoryBot.create(:parent, phone_number: '0755800000') }
    let!(:first_parent2) { FactoryBot.create(:parent, phone_number: '0755800001') }
    let!(:duplicated_first_parent1) { FactoryBot.create(:parent, phone_number: '0755800000') }
    let!(:duplicated_first_parent2) { FactoryBot.create(:parent, phone_number: '0755800001') }
    let!(:first_child) { FactoryBot.create(:child, first_name: 'preNom', last_name: 'nOm', parent1: first_parent1, parent2: first_parent2) }
    let!(:duplicated_first_child) { FactoryBot.create(:child, first_name: 'duplicate Prenom ', last_name: 'duplicate Nom', parent1: duplicated_first_parent1, parent2: duplicated_first_parent2) }
    let!(:group) { FactoryBot.create(:group, expected_children_number: 0) }

    it "if at least one child is not active delete the recent parents and put all children in the same siblings group" do
      group.update(started_at: Time.zone.now.prev_occurring(:monday), support_module_programmed: 1)
      first_child.update(group: group, group_status: 'active')

      subject.call
      expect(duplicated_first_parent1.reload.discarded?).to eq(true)
      expect(duplicated_first_parent2.reload.discarded?).to eq(true)
      expect(duplicated_first_child.reload.parent1_id).to eq(first_parent1.id)
      expect(duplicated_first_child.reload.parent2_id).to eq(first_parent2.id)
    end
  end
end
