require 'rails_helper'

RSpec.describe ChildrenSupportModule::SelectDefaultSupportModuleService do
  let!(:group) { FactoryBot.create(:group, expected_children_number: 0) }
  subject { ChildrenSupportModule::SelectDefaultSupportModuleService.new(group.id) }

  describe '#call' do
    let!(:group) { FactoryBot.create(:group, expected_children_number: 0) }
    let!(:support_module1) { FactoryBot.create(:support_module, name: 'Module 1', age_ranges: [SupportModule::FOUR_TO_ELEVEN], theme: 'songs') }
    let!(:support_module2) { FactoryBot.create(:support_module, name: 'Module 2') }
    let!(:support_module3) { FactoryBot.create(:support_module, name: 'Module 3', age_ranges: [SupportModule::TWELVE_TO_SEVENTEEN], theme: 'songs') }
    let!(:less_than_eleven_specific_default_support_module) { FactoryBot.create(:support_module, name: ENV['LESS_THAN_ELEVEN_SPECIFIC_DEFAULT_SUPPORT_MODULE_NAME'], age_ranges: [SupportModule::FOUR_TO_ELEVEN]) }
    let!(:more_than_twelve_specific_default_support_module) { FactoryBot.create(:support_module, name: ENV['MORE_THAN_TWELVE_SPECIFIC_DEFAULT_SUPPORT_MODULE_NAME'], age_ranges: [SupportModule::TWELVE_TO_SEVENTEEN]) }
    let!(:parent1) { FactoryBot.create(:parent) }
    let!(:parent2) { FactoryBot.create(:parent) }
    let!(:child) { FactoryBot.create(:child, parent1: parent1, group: group, group_status: 'active', birthdate: Faker::Date.between(from: 10.months.ago, to: 6.months.ago)) }

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
      around(:each) do |example|
        ChildrenSupportModule.skip_callback(:update, :after, :select_for_siblings)
        example.run
        ChildrenSupportModule.set_callback(:update, :after, :select_for_siblings)
      end

      let!(:sibling) { FactoryBot.create(:child, parent1: parent1, group: group, group_status: 'active', birthdate: Faker::Date.between(from: 16.months.ago, to: 13.months.ago)) }
      let!(:csm) { FactoryBot.create(:children_support_module, child: child, parent: parent1, support_module: nil, available_support_module_list: [support_module1.id, support_module2.id]) }
      let!(:sibling_csm) { FactoryBot.create(:children_support_module, child: sibling, parent: parent1, support_module: nil, available_support_module_list: []) }

      it 'does not give the sibling the choice-based module of the current child' do
        subject.call
        csm.reload
        sibling_csm.reload
        expect(csm.support_module).to eq support_module1
        expect(sibling_csm.support_module).not_to eq support_module1
      end

      # 4e passe du service : le filet de sécurité couvre tous les enfants
      # actifs, pas seulement les courants. Sans lui le frère/sœur restait à
      # nil et bloquait l'export logistique de toute la cohorte.
      it 'rescues the sibling with the age-based fallback module' do
        subject.call
        expect(sibling_csm.reload.support_module).to eq more_than_twelve_specific_default_support_module
      end
    end

    # Le case sur child.months s'arrêtait à 35 mois : au-delà, support_module
    # restait nil et l'opération était quand même comptée comme réussie.
    context 'when the child is older than 35 months' do
      # Prérequis : un module par défaut doit exister pour la tranche
      # thirty_to_thirty_five, sur laquelle le service plafonne tous les enfants
      # de 30 mois et plus — SupportModule.age_range_for, lui, continue de
      # renvoyer leur vraie tranche.
      let!(:thirty_to_thirty_five_default) do
        FactoryBot.create(:support_module, name: ENV['MORE_THAN_TWELVE_SPECIFIC_DEFAULT_SUPPORT_MODULE_NAME'],
                                           age_ranges: [SupportModule::THIRTY_TO_THIRTY_FIVE])
      end

      # La validation de birthdate ne s'applique qu'à la création : un enfant
      # inscrit à 28 mois dépasse 35 mois en cours d'accompagnement.
      let!(:older_child) do
        FactoryBot.create(:child, parent1: FactoryBot.create(:parent), group: group, group_status: 'active',
                                  birthdate: 28.months.ago.to_date)
                  .tap { |child| child.update_column(:birthdate, 40.months.ago.to_date) }
      end
      let!(:older_csm) do
        FactoryBot.create(:children_support_module, child: older_child, parent: older_child.parent1,
                                                    support_module: nil, available_support_module_list: [])
      end

      it 'assigns the age-based fallback module instead of leaving it nil' do
        subject.call
        expect(older_csm.reload.support_module).to eq thirty_to_thirty_five_default
      end
    end

    context 'when no fallback module exists for the age range' do
      let!(:lonely_child) do
        FactoryBot.create(:child, parent1: FactoryBot.create(:parent), group: group, group_status: 'active',
                                  birthdate: 8.months.ago.to_date)
      end
      let!(:lonely_csm) do
        FactoryBot.create(:children_support_module, child: lonely_child, parent: lonely_child.parent1,
                                                    support_module: nil, available_support_module_list: [])
      end

      before { less_than_eleven_specific_default_support_module.discard }

      it 'reports it to Rollbar instead of failing silently' do
        subject.call

        expect(lonely_csm.reload.support_module).to be_nil
        expect(Rollbar).to have_received(:error).with(
          'SelectDefaultSupportModuleService : aucun module attribuable',
          hash_including(group_id: group.id, children_support_modules: include(lonely_csm.id))
        )
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
