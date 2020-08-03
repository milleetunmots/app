FactoryBot.define do
  factory :media_document, class: Media::Document do

    name  { Faker::Movies::StarWars.planet }
    file do
      Rack::Test::UploadedFile.new(
        Dir.glob('db/seed/pdf/*.pdf').sample,
        'application/pdf'
      )
    end

  end
end
