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
#  folder_id    :bigint
#  image1_id    :bigint
#  image2_id    :bigint
#  image3_id    :bigint
#  link1_id     :bigint
#  link2_id     :bigint
#  link3_id     :bigint
#
# Indexes
#
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

class Medium < ApplicationRecord

  TYPES = %w[
    Media::Document
    Media::Form Media::Image
    Media::TextMessagesBundle
    Media::TextMessagesBundleDraft
    Media::Video
  ]

  include Discard::Model

  # ---------------------------------------------------------------------------
  # relations
  # ---------------------------------------------------------------------------

  belongs_to :folder,
    class_name: :MediaFolder,
    optional: true

  has_one :redirection_target

  # ---------------------------------------------------------------------------
  # validations
  # ---------------------------------------------------------------------------

  validates :name, presence: true

  # ---------------------------------------------------------------------------
  # scope
  # ---------------------------------------------------------------------------

  scope :without_folder, -> { where(folder: nil) }
  scope :documents, -> { where(type: "Media::Document") }
  scope :forms, -> { where(type: "Media::Form") }
  scope :images, -> { where(type: "Media::Image") }
  scope :videos, -> { where(type: "Media::Video") }
  scope :text_messages_bundles, -> { where(type: "Media::TextMessagesBundle") }
  scope :text_messages_bundle_drafts, -> { where(type: "Media::TextMessagesBundleDraft") }

  scope :for_redirections, -> {
    where(type: %w[Media::Form Media::Video])
  }

  # ---------------------------------------------------------------------------
  # versions history
  # ---------------------------------------------------------------------------

  has_paper_trail

  # ---------------------------------------------------------------------------
  # tags
  # ---------------------------------------------------------------------------

  acts_as_taggable

  include PgSearch
  multisearchable against: :name

end
