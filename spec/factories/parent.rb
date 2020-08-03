FactoryBot.define do
  factory :parent do

    gender            { Parent::GENDERS.sample }
    first_name        { Faker::Name.first_name }
    last_name         { Faker::Name.last_name }
    letterbox_name    { Faker::Name.name }
    address           { Faker::Address.street_address }
    city_name         { Faker::Address.city }
    postal_code       { Faker::Address.postcode }
    phone_number      { Faker::PhoneNumber.phone_number }
    terms_accepted_at { Faker::Date.backward }

  end
end
