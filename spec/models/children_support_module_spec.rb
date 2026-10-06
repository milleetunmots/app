# == Schema Information
#
# Table name: children_support_modules
#
#  id                            :bigint           not null, primary key
#  available_support_module_list :string           is an Array
#  book_condition                :string
#  book_condition_changed_at     :datetime
#  book_resent_on                :date
#  choice_date                   :date
#  is_completed                  :boolean          default(FALSE)
#  is_programmed                 :boolean          default(FALSE), not null
#  module_index                  :integer
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  book_id                       :bigint
#  child_id                      :bigint
#  parent_id                     :bigint
#  support_module_id             :bigint
#
# Indexes
#
#  index_children_support_modules_on_book_id            (book_id)
#  index_children_support_modules_on_child_id           (child_id)
#  index_children_support_modules_on_parent_id          (parent_id)
#  index_children_support_modules_on_support_module_id  (support_module_id)
#
# Foreign Keys
#
#  fk_rails_...  (book_id => books.id)
#
require 'rails_helper'

RSpec.describe ChildrenSupportModule, type: :model do
  describe '#select_for_siblings' do
    # Scenario: two siblings in the same active group share a child_support.
    # The younger child (current_child) is assigned a reading module with book A.
    # The older child is a sibling in the same group.
    # Two reading modules exist for different age ranges but share the SAME book.
    # Bug: `find_sibling_support_module` only excludes previously assigned module IDs,
    #       not book IDs — so the older sibling can receive a different module ID that
    #       still references the same book, creating a duplicate within the family.

    let!(:group)  { FactoryBot.create(:group) }
    let!(:parent1) { FactoryBot.create(:parent) }

    # child1 is older (15 months → twelve_to_seventeen age range)
    let!(:child1) do
      FactoryBot.create(:child,
                        parent1: parent1,
                        group: group,
                        group_status: 'active',
                        birthdate: 15.months.ago.to_date)
    end

    # child2 is younger (7 months → four_to_eleven age range).
    # Because create_support! merges true_siblings, child2 shares child1's child_support.
    # And because child_support#current_child orders by youngest (birthdate DESC), child2 is current_child.
    let!(:child2) do
      FactoryBot.create(:child,
                        parent1: parent1,
                        group: group,
                        group_status: 'active',
                        birthdate: 7.months.ago.to_date)
    end

    let!(:shared_book) { FactoryBot.create(:book) }
    let!(:other_book)  { FactoryBot.create(:book) }

    # Reading module for child2's age range — uses shared_book
    let!(:sm_reading_4_11) do
      FactoryBot.create(:support_module, theme: 'reading', for_bilingual: false,
                        age_ranges: [SupportModule::FOUR_TO_ELEVEN], book: shared_book)
    end

    # Reading module for child1's age range — also uses shared_book (the problematic duplicate)
    let!(:sm_reading_12_17_shared) do
      FactoryBot.create(:support_module, theme: 'reading', for_bilingual: false,
                        age_ranges: [SupportModule::TWELVE_TO_SEVENTEEN], book: shared_book)
    end

    # An alternative reading module for child1's age range with a different book
    let!(:sm_reading_12_17_other) do
      FactoryBot.create(:support_module, theme: 'reading', for_bilingual: false,
                        age_ranges: [SupportModule::TWELVE_TO_SEVENTEEN], book: other_book)
    end

    # Unprogrammed CSM for child2 (current_child), waiting to receive a module
    let!(:csm_child2) do
      FactoryBot.create(:children_support_module,
                        child: child2,
                        parent: parent1,
                        support_module: nil,
                        is_programmed: false,
                        is_completed: false,
                        available_support_module_list: [sm_reading_4_11.id.to_s])
    end

    it 'does not assign a module with the same book as the sibling already has' do
      # Assigning sm_reading_4_11 (shared_book) to child2 triggers select_for_siblings.
      # select_for_siblings should then find a module for child1 that does NOT use shared_book.
      csm_child2.update!(support_module: sm_reading_4_11, is_completed: true)

      child1_csm = ChildrenSupportModule.find_by(child: child1, parent: parent1, is_programmed: false)

      # After the fix, child1 should receive sm_reading_12_17_other (different book).
      # Before the fix, child1 receives sm_reading_12_17_shared (same book = duplicate).
      expect(child1_csm&.support_module&.book_id).not_to eq(shared_book.id)
      # garde-fou ajouté avec le fix jumeaux : le frère/sœur ne doit jamais
      # rester sans module, sinon il disparaît de l'export logistique
      expect(child1_csm&.support_module).to be_present
    end
  end

  # Des jumeaux partagent la même tranche d'âge : ils puisent dans le même
  # pool de modules, ce qui rend l'épuisement du vivier bien plus probable que
  # pour une fratrie d'âges différents.
  describe '#select_for_siblings avec des jumeaux' do
    let!(:group) { FactoryBot.create(:group) }
    let!(:parent1) { FactoryBot.create(:parent) }
    let(:birthdate) { 8.months.ago.to_date }

    let!(:twin_a) do
      FactoryBot.create(:child, parent1: parent1, group: group, group_status: 'active', birthdate: birthdate)
    end
    let!(:twin_b) do
      FactoryBot.create(:child, parent1: parent1, group: group, group_status: 'active', birthdate: birthdate)
    end

    let(:current_twin) { twin_a.reload.child_support.current_child }
    let(:other_twin) { [twin_a, twin_b].find { |child| child != current_twin } }

    let!(:chosen_book) { FactoryBot.create(:book) }
    let!(:other_book) { FactoryBot.create(:book) }

    # Même thème et même tranche d'âge pour les deux jumeaux
    let!(:chosen_module) do
      FactoryBot.create(:support_module, theme: 'reading', for_bilingual: false,
                                         age_ranges: [SupportModule::FOUR_TO_ELEVEN], book: chosen_book)
    end

    let(:csm) do
      FactoryBot.create(:children_support_module,
                        child: current_twin, parent: parent1, support_module: nil,
                        is_programmed: false, is_completed: false,
                        available_support_module_list: [chosen_module.id.to_s])
    end

    let(:other_twin_csm) { ChildrenSupportModule.find_by(child: other_twin, parent: parent1, is_programmed: false) }

    context 'quand un autre livre est disponible' do
      let!(:alternative_module) do
        FactoryBot.create(:support_module, theme: 'reading', for_bilingual: false,
                                           age_ranges: [SupportModule::FOUR_TO_ELEVEN], book: other_book)
      end

      it 'attribue un module au jumeau, avec un livre différent' do
        csm.update!(support_module: chosen_module, is_completed: true)

        expect(other_twin_csm.support_module).to eq alternative_module
        expect(other_twin_csm.support_module.book_id).not_to eq chosen_book.id
      end
    end

    # `where.not(book_id: [...])` génère un NOT IN, qui écartait aussi les
    # modules sans livre — alors qu'un module sans livre ne peut pas faire
    # doublon. Le jumeau se retrouvait sans module.
    context "quand le seul module restant n'a pas de livre" do
      let!(:bookless_module) do
        FactoryBot.create(:support_module, theme: 'reading', for_bilingual: false,
                                           age_ranges: [SupportModule::FOUR_TO_ELEVEN], book: nil)
      end

      it 'retient quand même ce module plutôt que de laisser le jumeau sans rien' do
        csm.update!(support_module: chosen_module, is_completed: true)

        expect(other_twin_csm.support_module).to eq bookless_module
      end
    end

    context 'quand un module avec livre et un module sans livre sont disponibles' do
      let!(:bookless_module) do
        FactoryBot.create(:support_module, theme: 'reading', for_bilingual: false,
                                           age_ranges: [SupportModule::FOUR_TO_ELEVEN], book: nil)
      end
      let!(:alternative_module) do
        FactoryBot.create(:support_module, theme: 'reading', for_bilingual: false,
                                           age_ranges: [SupportModule::FOUR_TO_ELEVEN], book: other_book)
      end

      it 'privilégie celui qui porte un livre' do
        csm.update!(support_module: chosen_module, is_completed: true)

        expect(other_twin_csm.support_module).to eq alternative_module
      end
    end

    context 'quand aucun module ne peut être attribué' do
      before { allow(Rollbar).to receive(:error) }

      it 'alerte Rollbar sans écrire un support_module nil' do
        csm.update!(support_module: chosen_module, is_completed: true)

        expect(Rollbar).to have_received(:error).with(
          'ChildrenSupportModule#select_for_siblings : aucun module attribuable au frère/sœur',
          hash_including(sibling_id: other_twin.id, parent_id: parent1.id)
        )
      end

      it "n'écrase pas un module déjà attribué au jumeau" do
        already_assigned = FactoryBot.create(:support_module, theme: 'songs', for_bilingual: false,
                                                              age_ranges: [SupportModule::FOUR_TO_ELEVEN],
                                                              book: other_book)
        existing = FactoryBot.create(:children_support_module,
                                     child: other_twin, parent: parent1,
                                     support_module: already_assigned, is_programmed: false)

        csm.update!(support_module: chosen_module, is_completed: true)

        expect(existing.reload.support_module).to eq already_assigned
      end
    end
  end
end
