FactoryBot.define do
  factory :media_video, class: Media::Video do

    name  { Faker::Movies::StarWars.planet }
    url   { Faker::Internet.url }

  end
end
