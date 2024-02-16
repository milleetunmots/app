# == Schema Information
#
# Table name: children
#
#  id                                         :bigint           not null, primary key
#  available_for_workshops                    :boolean          default(FALSE)
#  birthdate                                  :date             not null
#  discarded_at                               :datetime
#  family_redirection_unique_visit_rate       :float
#  family_redirection_url_unique_visits_count :integer
#  family_redirection_url_visits_count        :integer
#  family_redirection_urls_count              :integer
#  family_redirection_visit_rate              :float
#  first_name                                 :string           not null
#  gender                                     :string
#  group_end                                  :date
#  group_start                                :date
#  group_status                               :string           default("waiting")
#  last_name                                  :string           not null
#  pmi_detail                                 :string
#  registration_source                        :string
#  registration_source_details                :string
#  security_code                              :string
#  should_contact_parent1                     :boolean          default(FALSE), not null
#  should_contact_parent2                     :boolean          default(FALSE), not null
#  src_url                                    :string
#  created_at                                 :datetime         not null
#  updated_at                                 :datetime         not null
#  child_support_id                           :bigint
#  group_id                                   :bigint
#  parent1_id                                 :bigint           not null
#  parent2_id                                 :bigint
#
# Indexes
#
#  index_children_on_birthdate         (birthdate)
#  index_children_on_child_support_id  (child_support_id)
#  index_children_on_discarded_at      (discarded_at)
#  index_children_on_gender            (gender)
#  index_children_on_group_id          (group_id)
#  index_children_on_parent1_id        (parent1_id)
#  index_children_on_parent2_id        (parent2_id)
#
# Foreign Keys
#
#  fk_rails_...  (parent1_id => parents.id)
#  fk_rails_...  (parent2_id => parents.id)
#

require "rails_helper"

RSpec.describe Child, type: :model do
  let_it_be(:first_group, reload: true) { FactoryBot.create(:group, expected_children_number: 1) }
  let_it_be(:second_group, reload: true) { FactoryBot.create(:group, expected_children_number: 2) }

  let_it_be(:first_parent, reload: true) { FactoryBot.create(:parent, postal_code: 75_018) }
  let_it_be(:second_parent, reload: true) { FactoryBot.create(:parent, postal_code: 75_020) }
  let_it_be(:third_parent, reload: true) { FactoryBot.create(:parent, postal_code: 45_380) }
  let_it_be(:fourth_parent, reload: true) { FactoryBot.create(:parent, postal_code: 93_600) }
  let_it_be(:fifth_parent, reload: true) { FactoryBot.create(:parent, postal_code: 45_290) }

  let_it_be(:first_child, reload: true) { FactoryBot.create(:child, parent1: first_parent, parent2: second_parent, birthdate: Time.zone.today.prev_month, group: first_group, group_status: 'active') }
  let_it_be(:second_child, reload: true) { FactoryBot.create(:child, parent1: third_parent, parent2: second_parent, birthdate: Time.zone.today.prev_month(8), group: second_group, group_status: 'paused') }
  let_it_be(:third_child, reload: true) { FactoryBot.create(:child, parent1: first_parent, parent2: second_parent, birthdate: Time.zone.today.prev_month(14), group: second_group, group_status: 'active') }
  let_it_be(:fourth_child, reload: true) { FactoryBot.create(:child, parent1: first_parent, parent2: third_parent, birthdate: Time.zone.today.prev_day(3)) }
  let_it_be(:fifth_child, reload: true) { FactoryBot.create(:child, parent1: fourth_parent, parent2: fifth_parent, birthdate: Time.zone.today.prev_month(27)) }

  describe "Validations" do
    context "succeed" do
      it "if minimal attributes are present" do
        expect(first_child).to be_valid
      end

      it "if the child's gender is provided by Child::GENDERS" do
        first_child.update! gender: Child::GENDERS.sample
        expect(first_child).to be_valid
      end
    end

    context "fail" do
      let(:new_child) { FactoryBot.build(:child, first_name: first_child.first_name, birthdate: first_child.birthdate, parent1: first_child.parent1) }

      it "if the child's gender isn't provided by Child::GENDERS" do
        first_child.gender = 'X'
        expect(first_child).not_to be_valid
      end

      it "if the child doesn't have first name" do
        first_child.first_name = nil
        expect(first_child).not_to be_valid
      end

      it "if the child doesn't have last name" do
        first_child.last_name = nil
        expect(first_child).not_to be_valid
      end

      it "if the child doesn't have birthdate" do
        first_child.birthdate = nil
        expect(first_child).not_to be_valid
      end

      it "if the child doesn't have security code" do
        first_child.security_code = nil
        expect(first_child).not_to be_valid
      end

      it "if the child exists yet" do
        expect(new_child.save).to be false
      end
    end
  end

  describe "#min_birthdate" do
    context "returns" do
      it "the date 30 months ago" do
        expect(Child.min_birthdate).to eq Time.zone.today - 30.months
      end
    end
  end

  describe "#min_birthdate_alt" do
    context "returns" do
      it "the date 2 years ago" do
        expect(Child.min_birthdate_alt).to eq Time.zone.today - 2.years
      end
    end
  end

  describe "#max_birthdate" do
    context "returns" do
      it "today date" do
        expect(Child.max_birthdate).to eq Time.zone.today
      end
    end
  end

  describe ".months" do
    context "returns" do
      it "a number of months old" do
        expect(first_child.months).to eq 1
      end
    end
  end

  describe ".strict_siblings" do
    context "returns" do
      it "the child strict siblings" do
        expect(first_child.strict_siblings).to match_array [third_child]
      end
    end
  end

  describe ".true_siblings" do
    context "returns" do
      it "the child siblings" do
        expect(first_child.true_siblings).to match_array [second_child, third_child, fourth_child]
      end
    end
  end

  describe ".main_sibling" do
    context "returns" do
      let(:sixth_child) { FactoryBot.create(:child, parent1: fourth_parent, parent2: fifth_parent, birthdate: Time.zone.today.prev_month) }
      let(:seventh_child) { FactoryBot.create(:child, birthdate: Time.zone.today.prev_month(2)) }
      let(:eighth_child) { FactoryBot.create(:child, parent1: seventh_child.parent1 , parent2: seventh_child.parent2, birthdate: Time.zone.today.prev_month) }
      it "the child_support current_child if it exists" do
        expect(sixth_child.main_sibling).to eq fifth_child
        expect(seventh_child.child_support_id).to eq eighth_child.child_support_id
        expect(seventh_child.main_sibling).to be_nil
      end
    end
  end

  describe ".create_support!" do
    context "create" do
      it "child_support for the child and all their siblings" do
        first_child.create_support!
        expect(first_child.child_support).not_to be_nil
        first_child.true_siblings.each do |sibling|
          expect(sibling.child_support).to eq first_child.child_support
        end
      end
    end
  end

  describe ".add_to_group" do
    context "if the child has less than 4 months add to" do
      let(:date) { Time.zone.today.prev_day }
      let!(:third_group) { FactoryBot.create(:group, expected_children_number: 1, started_at: date.next_occurring(:monday)) }
      let!(:sixth_child) { FactoryBot.create(:child, birthdate: date.prev_month(4)) }
      let!(:seventh_child) { FactoryBot.create(:child, birthdate: date) }

      it "next available group in 4 months after its birthdate" do
        sixth_child.add_to_group
        expect(sixth_child.group_id).to eq third_group.id
      end

      it "no group if none will be available in 4 months after the its birthdate" do
        seventh_child.add_to_group
        expect(seventh_child.group_id).to be_nil
      end
    end

    context "if the child has not siblings" do
      let!(:eighth_child) { FactoryBot.create(:child, birthdate: Time.zone.today.prev_month(8)) }
      let!(:fourth_group) { FactoryBot.create(:group)}

      it "add it to the next available group" do
        eighth_child.add_to_group
        expect(eighth_child.group_id).to eq fourth_group.id
      end
    end

    context "if the main sibling has more than 36 months" do
      let!(:fifth_group) { FactoryBot.create(:group, expected_children_number: 1, started_at: Time.zone.today.next_occurring(:monday)) }
      let!(:ninth_child) { FactoryBot.create(:child) }
      let!(:tenth_child) { FactoryBot.create(:child, parent1: ninth_child.parent1, birthdate: Time.zone.today.prev_month(8)) }
      let!(:eleventh_child) { FactoryBot.create(:child, parent1: ninth_child.parent1, birthdate: Time.zone.today.prev_month(9)) }

      it "and if there are next available group, add the child to it or leave the child on waiting" do
        ninth_child.update(birthdate: ninth_child.birthdate.prev_month(50))
        tenth_child.add_to_group
        expect(tenth_child.group_id).to eq fifth_group.id
      end

      it "and if there is no next available group, leave the child on waiting" do
        # ninth_child.update(birthdate: ninth_child.birthdate.prev_month(50))
        # eleventh_child.add_to_group
        # expect(eleventh_child.group_id).to be_nil
      end
    end

    context "if the are main sibling group" do
      it "is started, leave the child on waiting" do
      end

      it "is not started, add the child to it" do
      end
    end
  end

  describe "#months_gteq" do
    context "returns" do
      it "children with a birthdate at the most equal to x months ago" do
        expect(Child.months_gteq(25)).to match_array [fifth_child]
      end
    end
  end

  describe "#months_lt" do
    context "returns" do
      it "children with a birthdate strictly greater than x months ago" do
        expect(Child.months_lt(1)).to match_array [fourth_child]
      end
    end
  end

  describe "#months_equals" do
    context "returns" do
      it "children with a birthdate equals to x months ago" do
        expect(Child.months_equals(1)).to eq [first_child]
        expect(Child.months_equals(8)).to eq [second_child]
        expect(Child.months_equals(14)).to eq [third_child]
        expect(Child.months_equals(27)).to eq [fifth_child]
      end
    end
  end

  describe "#months_between" do
    context "returns" do
      it "children with a birthdate between x and y months ago" do
        expect(Child.months_between(2, 15)).to match_array [second_child, third_child]
      end
    end
  end

  describe "#months_between_0_and_12" do
    context "returns" do
      it "children with a birthdate between 0 and 12 months ago" do
        expect(Child.months_between_0_and_12).to match_array [first_child, second_child, fourth_child]
      end
    end
  end

  describe "#months_between_12_and_24" do
    context "returns" do
      it "children with a birthdate between 12 and 24 months ago" do
        expect(Child.months_between_12_and_24).to match_array [third_child]
      end
    end
  end

  describe "#months_more_than_24" do
    context "returns" do
      it "children with a birthdate more than 24 months ago" do
        expect(Child.months_more_than_24).to match_array [fifth_child]
      end
    end
  end

  describe "#with_support" do
    context "returns" do
      before do
        second_child.update_column(:child_support_id, :nil)
        third_child.update_column(:child_support_id, :nil)
      end

      it "children with child_support" do
        expect(Child.with_support).to match_array [first_child, fourth_child, fifth_child]
      end
    end
  end

  describe "#without_support" do
    context "returns" do
      before do
        second_child.update_column(:child_support_id, :nil)
        third_child.update_column(:child_support_id, :nil)
      end

      it "children without child_support" do
        expect(Child.without_support).to match_array [second_child, third_child]
      end
    end
  end

  describe "#postal_code_contains" do
    context "returns" do
      it "children with first parent's postal code contains the parameter" do
        expect(Child.postal_code_contains(501)).to match_array [first_child, third_child, fourth_child]
      end
    end
  end

  describe "#postal_code_ends_with" do
    context "returns" do
      it "children with first parent's postal code ends with the parameter" do
        expect(Child.postal_code_ends_with(600)).to match_array [fifth_child]
      end
    end
  end

  describe "#postal_code_equals" do
    context "returns" do
      it "children with first parent's postal code is the parameter" do
        expect(Child.postal_code_equals(45380)).to match_array [second_child]
      end
    end
  end

  describe "#postal_code_starts_with" do
    context "returns" do
      it "children with first parent's postal code starts with the parameter" do
        expect(Child.postal_code_contains(75)).to match_array [first_child, third_child, fourth_child]
      end
    end
  end

  describe "#with_group" do
    context "returns" do
      it "children with group" do
        expect(Child.with_group).to match_array [first_child, second_child, third_child]
      end
    end
  end

  describe "#without_group" do
    context "returns" do
      it "children without group" do
        expect(Child.without_group).to match_array [fourth_child, fifth_child]
      end
    end
  end

  describe "#active_group_id_in" do
    context "returns" do
      it "children in the group in parameter and doesn't have quit" do
        expect(Child.active_group_id_in(second_group.id)).to match_array [third_child]
      end
    end
  end

  describe "#without_parent_text_message_since" do
    context "returns" do
      let_it_be(:text_message) { FactoryBot.create(:text_message, related: third_parent, occurred_at: Time.zone.today.prev_month(1)) }

      it "children with parents who don't have text message since the parameter" do
        expect(Child.without_parent_text_message_since(Time.zone.today.prev_month(2))).to match_array [first_child, third_child, fifth_child]
      end
    end
  end
end
