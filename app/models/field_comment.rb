# == Schema Information
#
# Table name: comments
#
#  id           :bigint           not null, primary key
#  field        :string
#  related_type :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  author_id    :bigint
#  related_id   :bigint
#
# Indexes
#
#  index_comments_on_author_id                    (author_id)
#  index_comments_on_related_type_and_related_id  (related_type,related_id)
#
# Foreign Keys
#
#  fk_rails_...  (author_id => admin_users.id)
#

class FieldComment < ApplicationRecord

  # ---------------------------------------------------------------------------
  # relations
  # ---------------------------------------------------------------------------

  belongs_to :author, class_name: :AdminUser
  belongs_to :related, polymorphic: true

  # ---------------------------------------------------------------------------
  # validations
  # ---------------------------------------------------------------------------

  validates :field,
            presence: true,
            inclusion: {
              in: -> (o) {
                o.related.attributes.keys
              }
            }

  # ---------------------------------------------------------------------------
  # scopes
  # ---------------------------------------------------------------------------

  scope :posted_by, ->(model) { where(author: model) }
  scope :relating, ->(model) { where(related: model) }

  # ---------------------------------------------------------------------------
  # callbacks
  # ---------------------------------------------------------------------------

  # always use base class in case of STI
  before_save do
    self.related_type = related_type.constantize.base_class.to_s
  end

end
