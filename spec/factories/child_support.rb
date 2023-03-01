FactoryBot.define do
  factory :child_support do
    association :current_child, factory: :child
  end
end
