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

class Media::TextMessagesBundle < Medium

  # ---------------------------------------------------------------------------
  # relations
  # ---------------------------------------------------------------------------

  belongs_to :image1,
             class_name: 'Media::Image',
             optional: true
  belongs_to :image2,
             class_name: 'Media::Image',
             optional: true
  belongs_to :image3,
             class_name: 'Media::Image',
             optional: true

  # ---------------------------------------------------------------------------
  # validations
  # ---------------------------------------------------------------------------

  validates :body1, presence: true
  validates :body2,
            presence: true,
            if: Proc.new { |o| o.image2 }
  validates :body3,
            presence: true,
            if: Proc.new { |o| o.image3 }

end
