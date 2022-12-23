FactoryBot.define do
  factory :workshop do
    animator factory: :admin_user

    workshop_date { Faker::Date.forward(days: 23) }
    address { Faker::Address.street_address }
    postal_code { Faker::Address.postcode }
    city_name { Faker::Address.city }
    invitation_message { Faker::Lorem.paragraph(sentence_count: 2) }
  end
end
