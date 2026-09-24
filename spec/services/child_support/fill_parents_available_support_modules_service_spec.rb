require 'rails_helper'

RSpec.describe ChildSupport::FillParentsAvailableSupportModulesService do

  let(:module_index) { 1 }
  let!(:group) do
    FactoryBot.create(:group, started_at: Date.current.beginning_of_week(:monday)).tap do |group|
      group.update!(support_module_sent_dates: { module_index.to_s => Date.current.to_s })
    end
  end
  let!(:parent1) { FactoryBot.create(:parent) }

  subject { described_class.new(group.id, module_index) }

  # La validation de birthdate ne s'applique qu'à la création : un enfant inscrit
  # à 30 mois — le maximum autorisé par Child.min_birthdate — dépasse les 44 mois
  # du référentiel avant la fin de ses deux ans d'accompagnement.
  def child_aged(months)
    FactoryBot.create(:child, parent1: parent1, group: group, group_status: 'active',
                              birthdate: 20.months.ago.to_date)
              .tap do |child|
                child.update_column(:birthdate, months.months.ago.to_date)
                child.create_support! unless child.child_support
              end
  end

  describe 'un enfant plus âgé que le référentiel' do
    # Ni `reading` de niveau 1 ni `for_bilingual`, tous deux écartés par
    # find_available_support_modules — la factory tire ces deux champs au hasard.
    let!(:last_range_module) do
      FactoryBot.create(:support_module, age_ranges: [SupportModule::FORTY_ONE_TO_FORTY_FOUR],
                                         theme: SupportModule::LANGUAGE, level: 1, for_bilingual: false)
    end

    # Sans plafond, age_range_for renvoie une tranche vide au-delà de 44 mois,
    # la requête ne ramène aucun module et le parent se voit proposer une liste
    # vide — sans la moindre trace.
    it 'reçoit les modules de la dernière tranche plutôt qu-une liste vide' do
      child = child_aged(50)

      subject.call

      expect(child.child_support.reload.parent1_available_support_module_list)
        .to include(last_range_module.id.to_s)
    end

    it 'reçoit les mêmes modules qu-un enfant pile dans la dernière tranche' do
      older = child_aged(50)
      in_range = child_aged(42)

      subject.call

      in_range_list = in_range.child_support.reload.parent1_available_support_module_list
      expect(in_range_list).not_to be_empty # sinon l'égalité ci-dessous ne prouve rien
      expect(older.child_support.reload.parent1_available_support_module_list).to eq in_range_list
    end
  end
end
