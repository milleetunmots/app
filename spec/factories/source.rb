FactoryBot.define do
  factory :source do
    name { Faker::Team.name }
    channel { (Source::CHANNEL_LIST - ['pmi', 'caf']).sample }
  end
end
