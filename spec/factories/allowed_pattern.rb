FactoryBot.define do
  factory :allowed_pattern do
    kind { 'url' }
    match_type { 'domain' }
    sequence(:value) { |n| "partenaire#{n}.fr" }

    trait :phone_number do
      kind { 'phone_number' }
      match_type { 'exact' }
      sequence(:value) { |n| format('08101234%02d', n % 100) }
    end
  end
end
