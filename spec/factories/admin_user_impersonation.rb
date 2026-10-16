FactoryBot.define do
  factory :admin_user_impersonation do
    association :operator, factory: :admin_user, user_role: 'contributor'
    association :target, factory: :admin_user, user_role: 'caller'
    started_at { Time.current }
  end
end
