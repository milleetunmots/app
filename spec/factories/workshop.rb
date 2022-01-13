FactoryBot.define do
  factory :workshop do
    animator factory: :admin_user

    topic { Workshop::TOPICS.sample }
    workshop_date { Faker::Date.forward(days: 23) }
    address { Faker::Date.forward(days: 23) }
    postal_code { Faker::Address.postcode }
    city_name { Faker::Address.city }
    land { Faker::Address.city}
    invitation_message { Faker::Lorem.paragraph(sentence_count: 2) }


    # tag_list { FactoryBot.create_list :tag, 2 }
    # events { FactoryBot.create_list :workshop_participation, 3, occurred_at: workshop_date, body: name }

  end
end
