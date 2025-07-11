FactoryBot.define do
  factory :book do

    ean { Faker::Number.number(digits: 10) }
    title { Faker::Book.title }
  end
end
