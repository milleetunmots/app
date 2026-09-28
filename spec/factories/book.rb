FactoryBot.define do
  factory :book do

    ean { Faker::Number.number(digits: 10) }
    title { Faker::Book.title }

    trait :with_interior_photos do
      transient do
        interior_photos_count { 2 }
      end

      after(:build) do |book, evaluator|
        Rails.root.glob('db/seed/img/cbfd/good/*.jpg')
             .first(evaluator.interior_photos_count)
             .each do |path|
          book.interior_photos.attach(
            io: File.open(path),
            filename: File.basename(path),
            content_type: 'image/jpeg'
          )
        end
      end
    end
  end
end
