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

class Medium < ApplicationRecord

  include Discard::Model

  # ---------------------------------------------------------------------------
  # relations
  # ---------------------------------------------------------------------------

  belongs_to :folder,
             class_name: :MediaFolder,
             optional: true

  # ---------------------------------------------------------------------------
  # validations
  # ---------------------------------------------------------------------------

  validates :name, presence: true

  # ---------------------------------------------------------------------------
  # scope
  # ---------------------------------------------------------------------------

  scope :without_folder, -> { where(folder: nil) }
  scope :images, -> { where(type: 'Media::Image') }
  scope :videos, -> { where(type: 'Media::Video') }
  scope :text_messages, -> { where(type: 'Media::TextMessage') }
  scope :text_messages_bundles, -> { where(type: 'Media::TextMessagesBundle') }

  # ---------------------------------------------------------------------------
  # versions history
  # ---------------------------------------------------------------------------

  has_paper_trail

  # ---------------------------------------------------------------------------
  # tags
  # ---------------------------------------------------------------------------

  acts_as_taggable

end
