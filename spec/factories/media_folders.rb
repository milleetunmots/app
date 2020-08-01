FactoryBot.define do
  factory :media_folder do
    name  { Faker::Movies::StarWars.planet }
  end
end
