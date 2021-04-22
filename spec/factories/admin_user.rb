FactoryBot.define do
  factory :admin_user do
    name      { Faker::Name.name }
    email     { Faker::Internet.email }
    password  { Faker::Internet.password }
  end
end
