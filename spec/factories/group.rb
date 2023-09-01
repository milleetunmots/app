FactoryBot.define do
  factory :group do
    name { Faker::Team.name }
    expected_children_number { 500 }
    started_at { Faker::Date.forward.next_occurring(:monday) }
  end
end
