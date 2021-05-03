# == Schema Information
#
# Table name: support_modules
#
#  id           :bigint           not null, primary key
#  ages         :string           not null
#  discarded_at :datetime
#  name         :string
#  start_at     :date
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_support_modules_on_discarded_at  (discarded_at)
#

FactoryBot.define do
  factory :support_module do
    name { Faker::Lorem.word }
    ages { SupportModule::AGES.sample }
  end
end
