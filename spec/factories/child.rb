FactoryBot.define do
  factory :child do
    association :parent1, factory: :parent
    
    birthdate {
      Faker::Date.between(from: Child.min_birthdate, to: Child.max_birthdate)
    }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    registration_source { Child::REGISTRATION_SOURCES.sample }
    registration_source_details { Faker::Movies::StarWars.planet }
  end
end
