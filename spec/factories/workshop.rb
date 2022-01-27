FactoryBot.define do
  factory :workshop do
    animator factory: :admin_user

    topic { Workshop::TOPICS.sample }
    workshop_date { Faker::Date.forward(days: 23) }
    address { Faker::Date.forward(days: 23) }
    postal_code { Faker::Address.postcode }
    city_name { Faker::Address.city }
    invitation_message { Faker::Lorem.paragraph(sentence_count: 2) }

  end
end
