FactoryBot.define do
  factory :child_support do
    association :current_child, factory: :child

    is_bilingual { ChildSupport::IS_BILINGUAL_OPTIONS.sample }
  end
end
