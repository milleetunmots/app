# == Schema Information
#
# Table name: events
#
#  id           :bigint           not null, primary key
#  body         :text
#  occurred_at  :datetime
#  related_type :string
#  type         :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  related_id   :bigint
#
# Indexes
#
#  index_events_on_related_type_and_related_id  (related_type,related_id)
#  index_events_on_type                         (type)
#

class Event < ApplicationRecord

  # ---------------------------------------------------------------------------
  # relations
  # ---------------------------------------------------------------------------

  belongs_to :related, polymorphic: true

  # ---------------------------------------------------------------------------
  # validations
  # ---------------------------------------------------------------------------

  validates :occurred_at, presence: true

  # ---------------------------------------------------------------------------
  # scope
  # ---------------------------------------------------------------------------

  scope :text_messages, -> { where(type: 'TextMessage') }

end
