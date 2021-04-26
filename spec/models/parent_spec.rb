# == Schema Information
#
# Table name: parents
#
#  id                                  :bigint           not null, primary key
#  address                             :string           not null
#  city_name                           :string           not null
#  discarded_at                        :datetime
#  email                               :string
#  first_name                          :string           not null
#  gender                              :string           not null
#  is_ambassador                       :boolean
#  is_lycamobile                       :boolean
#  job                                 :string
#  last_name                           :string           not null
#  letterbox_name                      :string
#  phone_number                        :string           not null
#  phone_number_national               :string
#  postal_code                         :string           not null
#  redirection_unique_visit_rate       :float
#  redirection_url_unique_visits_count :integer
#  redirection_url_visits_count        :integer
#  redirection_urls_count              :integer
#  redirection_visit_rate              :float
#  terms_accepted_at                   :datetime
#  created_at                          :datetime         not null
#  updated_at                          :datetime         not null
#
# Indexes
#
#  index_parents_on_address                (address)
#  index_parents_on_city_name              (city_name)
#  index_parents_on_discarded_at           (discarded_at)
#  index_parents_on_email                  (email)
#  index_parents_on_first_name             (first_name)
#  index_parents_on_gender                 (gender)
#  index_parents_on_is_ambassador          (is_ambassador)
#  index_parents_on_job                    (job)
#  index_parents_on_last_name              (last_name)
#  index_parents_on_phone_number_national  (phone_number_national)
#  index_parents_on_postal_code            (postal_code)
#

require "rails_helper"

RSpec.describe Parent, type: :model do
  describe "Validations" do
    context "succeed" do
      it "if minimal attributes are present" do
        expect(FactoryBot.build_stubbed(:parent)).to be_valid
      end
    end

    context "fail" do
      it "if the parent doesn't have gender" do
        expect(FactoryBot.build_stubbed(:parent, gender: nil)).to be_invalid
      end

      it "if the parent gender isn't provided by Parent::GENDERS" do
        expect(FactoryBot.build_stubbed(:parent, gender: "x")).to be_invalid
      end

      it "if the parent doesn't have firstname" do
        expect(FactoryBot.build_stubbed(:parent, first_name: nil)).to be_invalid
      end

      it "if the parent doesn't have lastname" do
        expect(FactoryBot.build_stubbed(:parent, last_name: nil)).to be_invalid
      end

      it "if the parent doesn't have letterbox" do
        expect(FactoryBot.build_stubbed(:parent, letterbox_name: nil)).to be_invalid
      end

      it "if the parent doesn't have address" do
        expect(FactoryBot.build_stubbed(:parent, address: nil)).to be_invalid
      end

      it "if the parent doesn't have city" do
        expect(FactoryBot.build_stubbed(:parent, city_name: nil)).to be_invalid
      end

      it "if the parent doesn't have postal code" do
        expect(FactoryBot.build_stubbed(:parent, postal_code: nil)).to be_invalid
      end

      it "if the parent doesn't have phone number" do
        expect(FactoryBot.build_stubbed(:parent, phone_number: nil)).to be_invalid
      end

      it "if the parent's email doesn't have the correct format" do
        parent = FactoryBot.build_stubbed(:parent, email: Faker::Internet.email)
        expect(parent.email). to match(Parent::REGEX_VALID_EMAIL)
      end

      it "if a parent with same email already exists" do
        @existing = FactoryBot.create(:parent, email: "parent@mail.io")
        expect(FactoryBot.build_stubbed(:parent, email: "parent@mail.io")).to be_invalid
      end

      it "if the parent doesn't accept the terms" do
        expect(FactoryBot.build_stubbed(:parent, terms_accepted_at: nil)). to be_invalid
      end
    end
  end

  describe ".children" do
    context "return" do
      it "parent's children" do
        parent = FactoryBot.create(:parent)
        first_child = FactoryBot.create(:child)
        second_child = FactoryBot.create(:child)
        third_child = FactoryBot.create(:child)
        first_child.parent1 = parent
        second_child.parent1 = parent
        third_child.parent2 = parent
        first_child.save
        second_child.save
        third_child.save
        expect(parent.children).to match_array [first_child, second_child, third_child]
      end
    end
  end

  describe ".first_children" do
    context "returns" do
      it "parent's first children" do
        parent = FactoryBot.create(:parent)
        first_child = FactoryBot.create(:child)
        second_child = FactoryBot.create(:child)
        first_child.parent1 = parent
        second_child.parent1 = parent
        first_child.save
        second_child.save
        expect(parent.first_child).to eq first_child
      end
    end
  end

  describe "#first_child_couples" do
    context "returns" do
      it "table of parent_id, first_child_id couples" do
        parent1 = FactoryBot.create(:parent)
        first_child = FactoryBot.create(:child)
        parent1.parent1_children = [first_child]
        parent1.save
        expect(Parent.first_child_couples.first["parent_id"]).to eq parent1.id
        expect(Parent.first_child_couples.first["first_child_id"]).to eq first_child.id
      end
    end
  end

  describe "#mothers" do
    context "returns" do
      it "the mothers" do
        mother1 = FactoryBot.create(:parent, gender: Parent::GENDER_FEMALE)
        mother2 = FactoryBot.create(:parent, gender: Parent::GENDER_FEMALE)
        mother3 = FactoryBot.create(:parent, gender: Parent::GENDER_FEMALE)
        expect(Parent.mothers).to match_array [mother1, mother2, mother3]
      end
    end
  end

  describe "#fathers" do
    context "returns" do
      it "the fathers" do
        father1 = FactoryBot.create(:parent, gender: Parent::GENDER_MALE)
        father2 = FactoryBot.create(:parent, gender: Parent::GENDER_MALE)
        expect(Parent.fathers).to match_array [father1, father2]
      end
    end
  end


end
