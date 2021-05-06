# == Schema Information
#
# Table name: children
#
#  id                                         :bigint           not null, primary key
#  birthdate                                  :date             not null
#  discarded_at                               :datetime
#  family_redirection_unique_visit_rate       :float
#  family_redirection_url_unique_visits_count :integer
#  family_redirection_url_visits_count        :integer
#  family_redirection_urls_count              :integer
#  family_redirection_visit_rate              :float
#  first_name                                 :string           not null
#  gender                                     :string
#  has_quit_group                             :boolean          default(FALSE), not null
#  last_name                                  :string           not null
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
  before(:each) do
    @parent1 = FactoryBot.create(:parent, postal_code: 75006)
    @parent2 = FactoryBot.create(:parent)
    @first_child = FactoryBot.create(:child, parent1: @parent1, parent2: @parent2, birthdate: Date.today.prev_month, should_contact_parent2: true)
    @second_child = FactoryBot.create(:child, parent1: @parent1, parent2: @parent2, birthdate: Date.today.prev_month(8))
    @third_child = FactoryBot.create(:child, parent1: @parent1, parent2: @parent2, birthdate: Date.today.prev_month(14))
    @fourth_child = FactoryBot.create(:child, birthdate: Date.today.yesterday, group: FactoryBot.create(:group))
    @fifth_child = FactoryBot.create(:child, birthdate: Date.today.prev_month(27), should_contact_parent1: true)
    @child_support = FactoryBot.create(:child_support, first_child: @fourth_child)
    @all_children = [@first_child, @second_child, @third_child, @fourth_child, @fifth_child]
  end

  describe "Validations" do
    context "succeed" do
      it "if minimal attributes are present" do
        expect(FactoryBot.build_stubbed(:child)).to be_valid
      end

      it "if the child's gender is provided by Child::GENDERS" do
        expect(FactoryBot.build_stubbed(:child, gender: Child::GENDERS.sample)).to be_valid
      end
    end

    context "fail" do
      it "if the child's gender isn't provided by Child::GENDERS" do
        expect(FactoryBot.build_stubbed(:child, gender: "x")).not_to be_valid
      end

      it "if the child doesn't have first name" do
        expect(FactoryBot.build_stubbed(:child, first_name: nil)).not_to be_valid
      end
      it "if the child doesn't have last name" do
        expect(FactoryBot.build_stubbed(:child, last_name: nil)).not_to be_valid
      end
      it "if the child doesn't have birthdate" do
        expect(FactoryBot.build_stubbed(:child, birthdate: nil)).not_to be_valid
      end
      it "if the child doesn't have registration source" do
        expect(FactoryBot.build_stubbed(:child, registration_source: nil)).not_to be_valid
      end
      it "if the child doesn't have registration source detail" do
        expect(FactoryBot.build_stubbed(:child, registration_source_details: nil)).not_to be_valid
      end
      it "if the child doesn't have security code" do
        expect(FactoryBot.build_stubbed(:child, security_code: nil)).not_to be_valid
      end
    end
  end

  describe ".strict_siblings" do
    context "returns" do
      it "the child siblings" do
        expect(@first_child.strict_siblings).to match_array [@second_child, @third_child]
        expect(@fourth_child.strict_siblings).to eq []
        expect(Child.all).to match_array @all_children
      end
    end
  end

  describe "#min_birthdate" do
    context "returns" do
      it "the date 34 months ago" do
        expect(Child.min_birthdate).to eq Date.today - 34.months
      end
    end
  end

  describe "#min_birthdate_alt" do
    context "returns" do
      it "the date 2 years ago" do
        expect(Child.min_birthdate_alt).to eq Date.today - 2.years
      end
    end
  end

  describe "#max_birthdate" do
    context "returns" do
      it "today date" do
        expect(Child.max_birthdate).to eq Date.today
      end
    end
  end

  describe ".months" do
    context "returns" do
      it "a number of months old" do
        child = FactoryBot.build_stubbed(:child, birthdate: Date.today.prev_month)
        expect(child.months).to eq 1
      end
    end
  end

  describe ".create_support!" do
    context "create" do
      it "child_support for the children and all strict siblings" do
        @first_child.create_support!
        expect(@first_child.child_support).not_to be_nil
        @first_child.strict_siblings.each do |sibling|
          expect(sibling.child_support).to eq @first_child.child_support
        end
      end
    end
  end

  describe "#months_gteq" do
    context "returns" do
      it "children with a birthdate at the most equal to x months ago" do
        expect(Child.months_gteq(25)).to match_array [@fifth_child]
        expect(Child.all).to match_array @all_children
      end
    end
  end

  describe "#months_lt" do
    context "returns" do
      it "children with a birthdate strictly greater than exactly x months ago" do
        expect(Child.months_lt(1)).to match_array [@fourth_child]
        expect(Child.all).to match_array @all_children
      end
    end
  end

  describe "#months_equals" do
    context "returns" do
      it "children with a birthdate equals to x months ago" do
        expect(Child.months_equals(1)).to eq [@first_child]
        expect(Child.months_equals(8)).to eq [@second_child]
        expect(Child.months_equals(14)).to eq [@third_child]
        expect(Child.months_equals(27)).to eq [@fifth_child]
        expect(Child.all).to match_array @all_children
      end
    end
  end

  describe "#months_between" do
    context "returns" do
      it "children with a birthdate between x and y months ago" do
        expect(Child.months_between(2, 15)).to match_array [@second_child, @third_child]
        expect(Child.all).to match_array @all_children
      end
    end
  end

  describe "#months_between_0_and_12" do
    context "returns" do
      it "children with a birthdate between 0 and 12 months ago" do
        expect(Child.months_between_0_and_12).to match_array [@first_child, @second_child, @fourth_child]
        expect(Child.all).to match_array @all_children
      end
    end
  end

  describe "#months_between_12_and_24" do
    context "returns" do
      it "children with a birthdate between 12 and 24 months ago" do
        expect(Child.months_between_12_and_24).to match_array [@third_child]
        expect(Child.all).to match_array @all_children
      end
    end
  end

  describe "#months_more_than_24" do
    context "returns" do
      it "children with a birthdate more than 24 months ago" do
        expect(Child.months_more_than_24).to match_array [@fifth_child]
        expect(Child.all).to match_array @all_children
      end
    end
  end

  describe "#with_support" do
    context "returns" do
      it "children with child_support" do
        expect(Child.with_support).to match_array [@fourth_child]
        expect(Child.all).to match_array @all_children
      end
    end
  end

  describe "#without_support" do
    context "returns" do
      it "children without child_support" do
        expect(Child.without_support).to match_array [@first_child, @second_child, @third_child, @fifth_child]
        expect(Child.all).to match_array @all_children
      end
    end
  end

  describe "#postal_code_contains" do
    context "returns" do
      it "children with parent's postal code contains the parameter" do
        expect(Child.postal_code_contains(500)).to match_array [@first_child, @second_child, @third_child]
        expect(Child.all).to match_array @all_children
      end
    end
  end

  describe "#postal_code_ends_with" do
    context "returns" do
      it "children with parent's postal code ends with the parameter" do
        expect(Child.postal_code_ends_with(06)).to match_array [@first_child, @second_child, @third_child]
        expect(Child.all).to match_array @all_children
      end
    end
  end

  describe "#postal_code_equals" do
    context "returns" do
      it "children with parent's postal code is the parameter" do
        expect(Child.postal_code_equals(75006)).to match_array [@first_child, @second_child, @third_child]
        expect(Child.all).to match_array @all_children
      end
    end
  end

  describe "#postal_code_starts_with" do
    context "returns" do
      it "children with parent's postal code starts with the parameter" do
        expect(Child.postal_code_contains(75)).to match_array [@first_child, @second_child, @third_child]
        expect(Child.all).to match_array @all_children
      end
    end
  end

  describe "#with_group" do
    context "returns" do
      it "children with group" do
        expect(Child.with_group).to match_array [@fourth_child]
        expect(Child.all).to match_array @all_children
      end
    end
  end

  describe "#without_group" do
    context "returns" do
      it "children without group" do
        expect(Child.without_group).to match_array [@first_child, @second_child, @third_child, @fifth_child]
        expect(Child.all).to match_array @all_children
      end
    end
  end

  describe "#with_parent_to_contact" do
    context "returns" do
      it "children with parent to contact" do
        expect(Child.with_parent_to_contact).to match_array [@first_child, @fifth_child]
        expect(Child.all).to match_array @all_children
      end
    end
  end
end
