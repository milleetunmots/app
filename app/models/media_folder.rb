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

class MediaFolder < ApplicationRecord

  # ---------------------------------------------------------------------------
  # relations
  # ---------------------------------------------------------------------------

  belongs_to :parent,
    class_name: "MediaFolder",
    optional: true
  has_many :children,
    class_name: "MediaFolder",
    foreign_key: "parent_id",
    dependent: :nullify
  has_many :media,
    foreign_key: "folder_id",
    dependent: :nullify

  # ---------------------------------------------------------------------------
  # validations
  # ---------------------------------------------------------------------------

  validates :name, presence: true
  validate :disallow_self_referential_parenthood

  def disallow_self_referential_parenthood
    return if id.blank?
    if parent_id == id
      errors.add(:parent_id, "cannot refer to itself")
    end
  end

  # ---------------------------------------------------------------------------
  # scope
  # ---------------------------------------------------------------------------

  scope :without_parent, -> { where(parent: nil) }

  # ---------------------------------------------------------------------------
  # versions history
  # ---------------------------------------------------------------------------

  has_paper_trail

end
