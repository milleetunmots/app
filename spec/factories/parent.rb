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

FactoryBot.define do
  factory :parent do

    gender { Parent::GENDERS.sample }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    letterbox_name { Faker::Name.name }
    address { Faker::Address.street_address }
    city_name { Faker::Address.city }
    postal_code { Faker::Address.postcode }
    phone_number { Faker::PhoneNumber.phone_number }
    terms_accepted_at { Faker::Date.backward }

  end
end
