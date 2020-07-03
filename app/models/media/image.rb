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
#
# Indexes
#
#  index_media_on_discarded_at  (discarded_at)
#  index_media_on_type          (type)
#

class Media::Image < Medium

  has_one_attached :file

  # ---------------------------------------------------------------------------
  # validations
  # ---------------------------------------------------------------------------

  validates :file,
            attached: true,
            content_type: %w(
              image/bmp
              image/gif
              image/jpeg
              image/jpg
              image/png
              image/tiff
              image/webp
            )

end
