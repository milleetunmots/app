FactoryBot.define do
  factory :aircall_call do
    association :caller, factory: :admin_user

    aircall_id { Faker::Number.number(digits: 5) }
    call_uuid { SecureRandom.uuid }
    direction { %w[inbound outbound].sample }
    answered { [true, false].sample }
  end
end