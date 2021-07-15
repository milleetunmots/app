FactoryBot.define do
  factory :tagging do
    taggable_type { 'Parent' }
    context { 'tags' }
  end
end