# == Schema Information
#
# Table name: media
#
#  id           :bigint           not null, primary key
#  body1        :text
#  body2        :text
#  body3        :text
#  discarded_at :datetime
#  name         :string
#  type         :string
#  url          :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  folder_id    :bigint
#
# Indexes
#
#  index_media_on_discarded_at  (discarded_at)
#  index_media_on_folder_id     (folder_id)
#  index_media_on_type          (type)
#
# Foreign Keys
#
#  fk_rails_...  (folder_id => media_folders.id)
#

class Media::TextMessagesBundle < Medium

  has_one_attached :image1
  has_one_attached :image2
  has_one_attached :image3

  # ---------------------------------------------------------------------------
  # validations
  # ---------------------------------------------------------------------------

  validates :body1, presence: true

  validates :image1, content_type: Media::Image::CONTENT_TYPES
  validates :image2, content_type: Media::Image::CONTENT_TYPES
  validates :image3, content_type: Media::Image::CONTENT_TYPES

end
