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
  describe "Validations" do
    context "succeed" do
      it "if minimal attributes are present" do
        expect(FactoryBot.build_stubbed(:child)).to be_valid
      end

      it "if the gender is provided by Child::GENDERS" do
        expect(FactoryBot.build_stubbed(:child, gender: Child::GENDERS.sample)).to be_valid
      end
    end

    context "fail" do
      it "if the child's gender isn't provided by Child::GENDERS" do
        expect(FactoryBot.build_stubbed(:child, gender: "x")).to be_invalid
      end

      it "if the child doesn't have first name" do
        expect(FactoryBot.build_stubbed(:child, first_name: nil)).to be_invalid
      end
      it "if the child doesn't have last name" do
        expect(FactoryBot.build_stubbed(:child, last_name: nil)). to be_invalid
      end
      it "if the child doesn't have birthdate" do
        expect(FactoryBot.build_stubbed(:child, birthdate: nil)). to be_invalid
      end
      it "if the child doesn't have registration source" do
        expect(FactoryBot.build_stubbed(:child, registration_source: nil)). to be_invalid
      end
      it "if the child doesn't have registration source detail" do
        expect(FactoryBot.build_stubbed(:child, registration_source_details: nil)). to be_invalid
      end
      it "if the child doesn't have security code" do
        expect(FactoryBot.build_stubbed(:child, security_code: nil)). to be_invalid
      end
    end
  end

  describe ".strict_siblings" do
    context "returns" do
      it "the child siblings" do
        parent1 = FactoryBot.create(:parent)
        parent2 = FactoryBot.create(:parent)
        first_child = FactoryBot.create(:child)
        second_child = FactoryBot.create(:child)
        third_child = FactoryBot.create(:child)
        first_child.parent1 = parent1
        first_child.parent2 = parent2
        second_child.parent1 = parent1
        second_child.parent2 = parent2
        third_child.parent1 = parent1
        third_child.parent2 = parent2
        first_child.save
        second_child.save
        third_child.save
        first_child_strict_siblings = [second_child, third_child]
        expect(first_child.strict_siblings).to match_array first_child_strict_siblings
      end

      it "empty array if the child doesn't have siblings" do
        parent3 = FactoryBot.create(:parent)
        parent4 = FactoryBot.create(:parent)
        fourth_child = FactoryBot.create(:child)
        fourth_child.parent1 = parent3
        fourth_child.parent2 = parent4
        expect(fourth_child.strict_siblings).to eq []
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

  describe "#months_gteq" do
    context "returns" do
      it "children with a birthdate at the most equal to x months ago" do
        child = FactoryBot.create(:child, birthdate: Date.today.prev_month)
        expect(Child.months_gteq(1)).to eq [child]
      end
    end
  end

  describe "#months_lt" do
    context "returns" do
      it "children with a birthdate strictly greater than exactly x months ago" do
        child = FactoryBot.create(:child, birthdate: Date.today.prev_day)
        expect(Child.months_lt(1)).to eq [child]
      end
    end
  end

  describe "#months_equals" do
    context "returns" do
      it "children with a birthdate equals to x months ago" do
        child = FactoryBot.create(:child, birthdate: Date.today.prev_month)
        expect(Child.months_equals(1)).to eq [child]
      end
    end
  end

  describe "#months_between" do
    context "returns" do
      it "children with a birthdate between x and y months ago" do
        child = FactoryBot.create(:child, birthdate: Date.today.prev_month(2))
        expect(Child.months_between(2, 3)).to eq [child]
      end
    end
  end

  describe "#months_between_0_and_12" do
    context "returns" do
      it "children with a birthdate between 0 and 12 months ago" do
        child = FactoryBot.create(:child, birthdate: Date.today.prev_month(2))
        expect(Child.months_between_0_and_12).to eq [child]
      end
    end
  end

  describe "#months_between_12_and_24" do
    context "returns" do
      it "children with a birthdate between 12 and 24 months ago" do
        child = FactoryBot.create(:child, birthdate: Date.today.prev_month(15))
        expect(Child.months_between_12_and_24).to eq [child]
      end
    end
  end

  describe "#months_more_than_24" do
    context "returns" do
      it "children with a birthdate more than 24 months ago" do
        child = FactoryBot.create(:child, birthdate: Date.today.prev_year(2))
        expect(Child.months_more_than_24).to eq [child]
      end
    end
  end
end
