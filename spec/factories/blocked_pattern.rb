FactoryBot.define do
  factory :blocked_pattern do
    kind { 'keyword' }
    sequence(:value) { |n| "terme-suspect-#{n}" }
  end
end
