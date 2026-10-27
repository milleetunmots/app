require 'rails_helper'

RSpec.describe ChildrenSupportModule::CheckBooksSavedService do
  describe '#call' do
    subject(:service) { described_class.new(group_ids: [group.id]).call }

    let!(:group) { FactoryBot.create(:group) }
    let!(:book) { FactoryBot.create(:book) }
    let!(:support_module) { FactoryBot.create(:support_module, book: book) }

    # le statut est posé après la création : la validation exige une cohorte pour certains statuts
    def create_child_with_choice(group: self.group, group_status: 'active', support_module: self.support_module)
      child = FactoryBot.create(:child, group: group, group_status: 'active')
      child.update_column(:group_status, group_status)
      FactoryBot.create(:children_support_module, child: child, parent: child.parent1, support_module: support_module)
    end

    context "quand le livre n'a pas été enregistré" do
      let!(:children_support_module) { create_child_with_choice }

      it 'signale le module avec sa cohorte' do
        expected_error = {
          message: "Des livres n'ont pas été enregistrés à l'export logistique",
          context: { group_id: group.id, children_support_module_ids: [children_support_module.id] }
        }

        expect(service.errors).to eq([expected_error])
      end

      it "n'enregistre pas le livre" do
        service

        expect(children_support_module.reload[:book_id]).to be_nil
      end
    end

    context 'quand le livre a été enregistré' do
      before { create_child_with_choice.update_column(:book_id, book.id) }

      it 'ne signale rien' do
        expect(service.errors).to be_empty
      end
    end

    %w[paused stopped disengaged].each do |group_status|
      context "pour un enfant #{group_status}" do
        before { create_child_with_choice(group_status: group_status) }

        it 'signale le module' do
          expect(service.errors.size).to eq(1)
        end
      end
    end

    %w[not_supported waiting].each do |group_status|
      context "pour un enfant #{group_status}" do
        before { create_child_with_choice(group_status: group_status) }

        it 'ne signale rien' do
          expect(service.errors).to be_empty
        end
      end
    end

    context "quand le module choisi n'a pas de livre" do
      before { create_child_with_choice(support_module: FactoryBot.create(:support_module)) }

      it 'ne signale rien' do
        expect(service.errors).to be_empty
      end
    end

    context 'pour un module déjà programmé' do
      before { create_child_with_choice.update_column(:is_programmed, true) }

      it 'ne signale rien' do
        expect(service.errors).to be_empty
      end
    end

    context 'pour le choix du parent 2' do
      before do
        child = FactoryBot.create(:child, group: group, group_status: 'active', parent2: FactoryBot.create(:parent))
        FactoryBot.create(:children_support_module, child: child, parent: child.parent2, support_module: support_module)
      end

      it 'ne signale rien' do
        expect(service.errors).to be_empty
      end
    end

    context 'pour plusieurs cohortes' do
      subject(:service) { described_class.new(group_ids: [group.id, other_group.id]).call }

      let!(:other_group) { FactoryBot.create(:group) }

      before do
        create_child_with_choice
        create_child_with_choice(group: other_group)
      end

      it 'signale chaque cohorte séparément' do
        expect(service.errors.map { |error| error[:context][:group_id] }).to contain_exactly(group.id, other_group.id)
      end
    end
  end
end
