FactoryBot.define do
  factory :media_form, class: Media::Form do

    name  { Faker::Movies::StarWars.planet }
    url   { Faker::Internet.url }

  end
end
