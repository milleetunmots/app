# == Schema Information
#
# Table name: media_folders
#
#  id         :bigint           not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  parent_id  :bigint
#
# Indexes
#
#  index_media_folders_on_parent_id  (parent_id)
#
# Foreign Keys
#
#  fk_rails_...  (parent_id => media_folders.id)
#

FactoryBot.define do
  factory :media_folder do
    name { Faker::Movies::StarWars.planet }
  end
end
