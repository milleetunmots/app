FactoryBot.define do
  factory :aircall_message do
    # association :child_support, factory: :child_support
    association :parent, factory: :parent
    association :caller, factory: :admin_user

    aircall_id { Faker::Number.number(digits: 5) }
    direction { %w[inbound outbound].sample }
  end
end