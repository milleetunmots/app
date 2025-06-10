require 'rails_helper'

RSpec.describe ChildrenSupportModule::SelectDefaultSupportModuleService do
  let!(:group) { FactoryBot.create(:group, expected_children_number: 0) }
  subject { ChildrenSupportModule::SelectDefaultSupportModuleService.new(group.id) }

  describe '#call' do
    let!(:support_module1) { FactoryBot.create(:support_module) }
    let!(:support_module2) { FactoryBot.create(:support_module) }
    let!(:support_module3) { FactoryBot.create(:support_module) }
    let!(:parent1) { FactoryBot.create(:parent) }
    let!(:parent2) { FactoryBot.create(:parent) }
    let!(:child) { FactoryBot.create(:child, parent1: parent1, group: group, group_status: 'active') }

    before { allow(Rollbar).to receive(:error) }

    context 'when children are missing child_support' do
      it 'logs missing children to Rollbar' do
        child.update_column(:child_support_id, nil)
        subject.call
        expect(Rollbar).to have_received(:error).with(
          "Certains enfants de la cohorte #{group.id} n'ont pas de fiche de suivi",
          children: [child.id],
          source: 'ChildrenSupportModule::SelectDefaultSupportModuleService'
        )
      end
    end

    context 'when child has sibling in same group' do
      let!(:sibling) { FactoryBot.create(:child, parent1: parent1, group: group, group_status: 'active', birthdate: child.birthdate.next_month) }
      let!(:csm) { FactoryBot.create(:children_support_module, child: sibling, parent: parent1, support_module: nil) }

      it 'does not update the children_support_module for the sibling' do
        subject.call
        csm.reload
        expect(csm.support_module).to be_nil
      end
    end

    context 'when selecting a default support module' do
      let!(:csm_parent1) { FactoryBot.create(:children_support_module, child: child, parent: parent1, support_module: nil, available_support_module_list: [support_module1.id, support_module2.id]) }

      context 'and there is no other parent' do
        it 'selects the first available support module' do
          subject.call
          csm_parent1.reload
          expect(csm_parent1.support_module).to eq(support_module1)
        end
      end

      context 'and the other parent has made a choice' do
        before { child.update_column(:parent2_id, parent2.id) }

        let!(:csm_parent2) { FactoryBot.create(:children_support_module, child: child, parent: parent2, support_module: support_module2, available_support_module_list: [support_module1.id, support_module2.id]) }

        it "selects the same support module as the other parent" do
          subject.call
          csm_parent1.reload
          expect(csm_parent1.support_module).to eq(support_module2)
        end
      end

      context 'and the other parent has not made a choice' do
        before { child.update_column(:parent2_id, parent2.id) }

        let!(:csm_parent2) { FactoryBot.create(:children_support_module, child: child, parent: parent2, support_module: nil, available_support_module_list: [support_module1.id, support_module2.id]) }

        it 'selects the first available support module' do
          subject.call
          csm_parent1.reload
          expect(csm_parent1.support_module).to eq(support_module1)
        end
      end
    end
  end
end