FactoryBot.define do
  factory :child_support do
    association :first_child, factory: :child
  end
end
