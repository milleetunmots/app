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
#  image1_id    :bigint
#  image2_id    :bigint
#  image3_id    :bigint
#
# Indexes
#
#  index_media_on_discarded_at  (discarded_at)
#  index_media_on_folder_id     (folder_id)
#  index_media_on_image1_id     (image1_id)
#  index_media_on_image2_id     (image2_id)
#  index_media_on_image3_id     (image3_id)
#  index_media_on_type          (type)
#
# Foreign Keys
#
#  fk_rails_...  (folder_id => media_folders.id)
#  fk_rails_...  (image1_id => media.id)
#  fk_rails_...  (image2_id => media.id)
#  fk_rails_...  (image3_id => media.id)
#

class Media::Image < Medium

  CONTENT_TYPES = %w(
    image/bmp
    image/gif
    image/jpeg
    image/jpg
    image/png
    image/tiff
    image/webp
  )

  has_one_attached :file

  # ---------------------------------------------------------------------------
  # validations
  # ---------------------------------------------------------------------------

  validates :file,
            attached: true,
            content_type: CONTENT_TYPES

end
