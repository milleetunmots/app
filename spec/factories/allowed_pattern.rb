FactoryBot.define do
  factory :allowed_pattern do
    kind { 'url' }
    match_type { 'domain' }
    sequence(:value) { |n| "partenaire#{n}.fr" }
  end
end
