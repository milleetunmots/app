require 'rails_helper'

# Toute la chaîne d'attribution des modules désigne un « enfant courant » par
# fratrie. Tant que le tri se faisait sur la seule `birthdate`, l'ordre n'était
# pas total pour des jumeaux : PostgreSQL renvoyait une ligne arbitraire, et les
# différentes sources pouvaient désigner deux enfants différents — laissant un
# jumeau sans module d'accompagnement.
RSpec.describe 'Désignation du current_child dans une fratrie de jumeaux' do
  let!(:group) { FactoryBot.create(:group) }
  let!(:parent1) { FactoryBot.create(:parent) }
  let(:birthdate) { 8.months.ago.to_date }

  let!(:twin_a) do
    FactoryBot.create(:child, parent1: parent1, group: group, group_status: 'active', birthdate: birthdate)
  end
  # twin_b rejoint la fiche de twin_a via create_support! -> true_siblings
  let!(:twin_b) do
    FactoryBot.create(:child, parent1: parent1, group: group, group_status: 'active', birthdate: birthdate)
  end

  let(:child_support) { twin_a.reload.child_support }
  let(:first_registered_twin) { [twin_a, twin_b].min_by(&:id) }

  it 'partage bien la même fiche de suivi' do
    expect(twin_b.reload.child_support).to eq child_support
  end

  it 'désigne le même enfant depuis toutes les sources' do
    from_child_support = child_support.current_child
    from_parent        = parent1.current_child
    from_sibling_scope = twin_a.current_sibling_in_group(group)

    expect(from_parent).to eq from_child_support
    expect(from_sibling_scope).to eq from_child_support
  end

  it 'désigne le jumeau inscrit en premier' do
    expect(child_support.current_child).to eq first_registered_twin
  end

  it "n'a qu'un seul current_child? dans la fratrie" do
    expect([twin_a.reload.current_child?, twin_b.reload.current_child?].count(true)).to eq 1
  end

  # Un UPDATE déplace la version de tuple en fin de page : l'ordre de scan
  # séquentiel change, ce qui reproduit le non-déterminisme observé en production.
  it "reste stable quand l'ordre physique des lignes change" do
    twin_a.update_column(:updated_at, 1.second.from_now)

    expect(ChildSupport.find(child_support.id).current_child).to eq first_registered_twin
    expect(Parent.find(parent1.id).current_child).to eq first_registered_twin
  end

  # Le has_one through joint `parents` ET `children` : un départageur `id` non
  # qualifié y provoquerait un PG::AmbiguousColumn.
  it 'résout parent1 / parent2 via le current_child sans ambiguïté de colonne' do
    expect { child_support.reload.parent1 }.not_to raise_error
    expect(child_support.parent1).to eq parent1
    expect(child_support.parent2).to be_nil
  end

  # Les fratries écartent les enfants archivés (current_sibling_in_group,
  # siblings_on_same_group). Si la fiche de suivi ne les écartait pas, elle
  # désignerait l'archivé pendant que le job SMS désigne son jumeau : les deux
  # moitiés de la chaîne d'attribution repartiraient sur deux enfants
  # différents, ce que ce fichier existe précisément pour empêcher.
  describe 'quand le jumeau désigné est archivé' do
    before { first_registered_twin.discard! }

    let(:remaining_twin) { [twin_a, twin_b].max_by(&:id) }

    it 'désigne le jumeau restant depuis toutes les sources' do
      expect(child_support.reload.current_child).to eq remaining_twin
      expect(parent1.reload.current_child).to eq remaining_twin
      expect(remaining_twin.reload.current_sibling_in_group(group)).to eq remaining_twin
    end

    it 'fait du jumeau restant le current_child? de la fratrie' do
      expect(remaining_twin.reload.current_child?).to be true
    end

    it 'résout encore parent1 via le current_child' do
      expect(child_support.reload.parent1).to eq parent1
    end
  end

  # L'invariant est écrit en commentaire dans parent.rb depuis l'origine, et il
  # était faux : current_child_couples désignait sur le seul MIN(children.id).
  describe 'Parent.current_child_couples' do
    def couple_for(parent)
      Parent.current_child_couples.find { |couple| couple['parent_id'] == parent.id }
    end

    it 'désigne le même enfant que Parent#current_child pour des jumeaux' do
      expect(couple_for(parent1)['current_child_id']).to eq parent1.current_child.id
    end

    it 'désigne le plus jeune actif, pas le premier inscrit' do
      other_parent = FactoryBot.create(:parent)
      FactoryBot.create(:child, parent1: other_parent, group: group, group_status: 'active',
                                birthdate: 20.months.ago.to_date)
      younger = FactoryBot.create(:child, parent1: other_parent, group: group, group_status: 'active',
                                          birthdate: 6.months.ago.to_date)

      expect(couple_for(other_parent)['current_child_id']).to eq younger.id
      expect(other_parent.current_child).to eq younger
    end

    it 'écarte les enfants archivés, comme Parent#current_child' do
      first_registered_twin.discard!
      remaining = [twin_a, twin_b].max_by(&:id)

      expect(couple_for(parent1)['current_child_id']).to eq remaining.id
      expect(parent1.reload.current_child).to eq remaining
    end

    it 'reste joignable par left_outer_joins_current_child' do
      expect(Parent.current_child_group_id_in(group.id)).to include(parent1)
    end
  end

  # `Child#siblings` n'apparie que sur `parent1_id`, alors que `create_support!`
  # regroupe via `true_siblings`, qui accepte les deux parents dans les deux
  # rôles. Une fratrie saisie avec les parents inversés partageait donc une fiche
  # sans être vue comme une fratrie par le périmètre d'attribution.
  describe 'fratrie dont les parents sont inversés d’un enfant à l’autre' do
    let!(:mother) { FactoryBot.create(:parent) }
    let!(:father) { FactoryBot.create(:parent) }
    let!(:eldest) do
      FactoryBot.create(:child, parent1: mother, parent2: father, group: group,
                                group_status: 'active', birthdate: 18.months.ago.to_date)
    end
    let!(:youngest) do
      FactoryBot.create(:child, parent1: father, parent2: mother, group: group,
                                group_status: 'active', birthdate: 6.months.ago.to_date)
    end

    it 'partage bien une fiche de suivi' do
      expect(youngest.reload.child_support).to eq eldest.reload.child_support
    end

    it 'voit les deux enfants comme une fratrie de la cohorte' do
      expect(eldest.reload.siblings_on_same_group).to contain_exactly(eldest, youngest)
      expect(eldest.have_siblings_on_same_group?).to be true
    end

    it 'désigne le même enfant courant que la fiche de suivi' do
      expect(eldest.reload.current_sibling_in_group(group)).to eq eldest.child_support.current_child
      expect(youngest.reload.current_child?).to be true
    end
  end

  describe 'fratries non jumelles' do
    let(:other_parent) { FactoryBot.create(:parent) }
    let!(:older) do
      FactoryBot.create(:child, parent1: other_parent, group: group, group_status: 'active',
                                birthdate: 20.months.ago.to_date)
    end
    let!(:younger) do
      FactoryBot.create(:child, parent1: other_parent, group: group, group_status: 'active',
                                birthdate: 6.months.ago.to_date)
    end

    it 'désigne toujours le plus jeune actif : le départageur ne change rien' do
      expect(older.reload.child_support.current_child).to eq younger
    end

    it 'priorise un actif plus vieux sur un non-actif plus jeune' do
      younger.update!(group_status: 'stopped')

      expect(older.reload.child_support.current_child).to eq older
    end
  end
end
