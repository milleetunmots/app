# == Schema Information
#
# Table name: events
#
#  id           :bigint           not null, primary key
#  body         :text
#  discarded_at :datetime
#  occurred_at  :datetime
#  related_type :string
#  type         :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  related_id   :bigint
#
# Indexes
#
#  index_events_on_discarded_at                 (discarded_at)
#  index_events_on_related_type_and_related_id  (related_type,related_id)
#  index_events_on_type                         (type)
#

class Event < ApplicationRecord

  include Discard::Model

  # ---------------------------------------------------------------------------
  # relations
  # ---------------------------------------------------------------------------

  belongs_to :related, polymorphic: true

  # ---------------------------------------------------------------------------
  # validations
  # ---------------------------------------------------------------------------

  validates :occurred_at, presence: true

  # ---------------------------------------------------------------------------
  # helpers
  # ---------------------------------------------------------------------------

  delegate :first_child,
           to: :related,
           prefix: true,
           allow_nil: true

  delegate :id,
           :group,
           :group_id,
           :group_name,
           :has_quit_group,
           to: :related_first_child,
           prefix: true,
           allow_nil: true

  # ---------------------------------------------------------------------------
  # scope
  # ---------------------------------------------------------------------------

  scope :text_messages, -> { where(type: 'Events::TextMessage') }
  scope :workshop_participations, -> { where(type: 'Events::WorkshopParticipation') }

  # ---------------------------------------------------------------------------
  # scopes
  # ---------------------------------------------------------------------------

  # this cannot be named related_first_child_... due to Ransack behavior
  def self.parent_first_child_group_id_in(*v)
    where(related: Parent.first_child_group_id_in(v))
  end

  # ---------------------------------------------------------------------------
  # ransack
  # ---------------------------------------------------------------------------

  def self.ransackable_scopes(auth_object = nil)
    %i(parent_first_child_group_id_in)
  end

end
