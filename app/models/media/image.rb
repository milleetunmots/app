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
#  theme        :string
#  type         :string
#  url          :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  airtable_id  :string
#  folder_id    :bigint
#  image1_id    :bigint
#  image2_id    :bigint
#  image3_id    :bigint
#  link1_id     :bigint
#  link2_id     :bigint
#  link3_id     :bigint
#  spot_hit_id  :string
#
# Indexes
#
#  index_media_on_airtable_id   (airtable_id) UNIQUE
#  index_media_on_discarded_at  (discarded_at)
#  index_media_on_folder_id     (folder_id)
#  index_media_on_image1_id     (image1_id)
#  index_media_on_image2_id     (image2_id)
#  index_media_on_image3_id     (image3_id)
#  index_media_on_link1_id      (link1_id)
#  index_media_on_link2_id      (link2_id)
#  index_media_on_link3_id      (link3_id)
#  index_media_on_type          (type)
#
# Foreign Keys
#
#  fk_rails_...  (folder_id => media_folders.id)
#  fk_rails_...  (image1_id => media.id)
#  fk_rails_...  (image2_id => media.id)
#  fk_rails_...  (image3_id => media.id)
#  fk_rails_...  (link1_id => media.id)
#  fk_rails_...  (link2_id => media.id)
#  fk_rails_...  (link3_id => media.id)
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
  WEIGHT_SIZE_RATIO = 0.5 # ratio file weight / image size (by experience)
  BUZZ_EXPERT_MAX_WEIGHT = 220_000

  # ---------------------------------------------------------------------------
  # relations
  # ---------------------------------------------------------------------------

  has_one_attached :file

  # ---------------------------------------------------------------------------
  # validations
  # ---------------------------------------------------------------------------

  validates :file,
            attached: true,
            content_type: CONTENT_TYPES

  # ---------------------------------------------------------------------------
  # callbacks
  # ---------------------------------------------------------------------------

  after_save :upload_file_to_spot_hit

  # ---------------------------------------------------------------------------
  # helpers
  # ---------------------------------------------------------------------------

  # max_byte_size in octets, e.g. 250_000
  def file_max_byte_size_variant(max_byte_size)
    return nil unless file.attached? && file.analyzed?

    return file if file.blob.byte_size <= max_byte_size

    # original
    width = file.blob.metadata['width']
    height = file.blob.metadata['height']
    wh_ratio = width / height.to_f

    # target
    w = Math.sqrt( (max_byte_size * wh_ratio) / (WEIGHT_SIZE_RATIO * 3) ).floor

    if w >= width
      file
    else
      file.variant(resize_to_limit: [w, w / wh_ratio])
    end
  end

  include PgSearch
  multisearchable against: :name


  def upload_file_to_spot_hit
    return unless attachment_changes['file'].present?

    service = SpotHit::UploadMediaService.new(self).call
    fail service.errors.join(', ') if service.errors.any?
  end

end
