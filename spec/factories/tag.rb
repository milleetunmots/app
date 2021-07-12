FactoryBot.define do
  factory :tag_2 do
    name { Faker::Name.first_name }
  end
end