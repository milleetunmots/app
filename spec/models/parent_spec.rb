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

require 'rails_helper'

RSpec.describe Parent, type: :model do

  describe "Validations" do
    context "succeed" do
      it "if minimal attributes are present" do
        expect(FactoryBot.build_stubbed(:parent)).to be_valid
      end
    end

    context "fail" do
      it "if the parent doesn't have gender" do
        expect(FactoryBot.build_stubbed(:parent, gender: nil)). to be_invalid
      end
      it "if the parent doesn't have firstname" do
        expect(FactoryBot.build_stubbed(:parent, first_name: nil)). to be_invalid
      end
      it "if the parent doesn't have lastname" do
        expect(FactoryBot.build_stubbed(:parent, last_name: nil)). to be_invalid
      end
      it "if the parent doesn't have letterbox" do
        expect(FactoryBot.build_stubbed(:parent, letterbox_name: nil)). to be_invalid
      end
      it "if the parent doesn't have address" do
        expect(FactoryBot.build_stubbed(:parent, address: nil)). to be_invalid
      end
      it "if the parent doesn't have city" do
        expect(FactoryBot.build_stubbed(:parent, city_name: nil)). to be_invalid
      end
      it "if the parent doesn't have postal code" do
        expect(FactoryBot.build_stubbed(:parent, postal_code: nil)). to be_invalid
      end
      it "if the parent doesn't have phone number" do
        expect(FactoryBot.build_stubbed(:parent, phone_number: nil)). to be_invalid
      end
      it "if the parent's email doesn't have the correct format" do
        parent = FactoryBot.build_stubbed(:parent, email: Faker::Internet.email)
        expect(parent.email). to match(Parent::REGEX_VALID_EMAIL)
      end
      it "if a parent with same email already exists" do
        @existing = FactoryBot.create(:parent, email:"parent@mail.io")
        expect(FactoryBot.build_stubbed(:parent, email: "parent@mail.io")).to be_invalid
      end
      it "if the parent doesn't accept the terms" do
        expect(FactoryBot.build_stubbed(:parent, terms_accepted_at: nil)). to be_invalid
      end

    end
  end
end
