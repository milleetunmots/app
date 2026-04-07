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
      FactoryBot.create(:support_module, theme: 'reading',
                        age_ranges: [SupportModule::FOUR_TO_ELEVEN], book: shared_book)
    end

    # Reading module for child1's age range — also uses shared_book (the problematic duplicate)
    let!(:sm_reading_12_17_shared) do
      FactoryBot.create(:support_module, theme: 'reading',
                        age_ranges: [SupportModule::TWELVE_TO_SEVENTEEN], book: shared_book)
    end

    # An alternative reading module for child1's age range with a different book
    let!(:sm_reading_12_17_other) do
      FactoryBot.create(:support_module, theme: 'reading',
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
    end
  end
end
