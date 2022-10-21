# == Schema Information
#
# Table name: events
#
#  id                   :bigint           not null, primary key
#  body                 :text
#  discarded_at         :datetime
#  occurred_at          :datetime
#  originated_by_app    :boolean          default(TRUE), not null
#  parent_response      :string
#  related_type         :string
#  spot_hit_status      :integer
#  subject              :string
#  type                 :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  related_id           :bigint
#  spot_hit_campaign_id :string
#  spot_hit_message_id  :string
#  workshop_id          :bigint
#
# Indexes
#
#  index_events_on_discarded_at                 (discarded_at)
#  index_events_on_related_type_and_related_id  (related_type,related_id)
#  index_events_on_type                         (type)
#  index_events_on_workshop_id                  (workshop_id)
#
# Foreign Keys
#
#  fk_rails_...  (workshop_id => workshops.id)
#

class Event < ApplicationRecord

  include Discard::Model

  # ---------------------------------------------------------------------------
  # constantes
  # ---------------------------------------------------------------------------

  SPOT_HIT_STATUS = ["En attente","Livré","Envoyé","En cours","Echec","Expiré"].freeze

  # ---------------------------------------------------------------------------
  # relations
  # ---------------------------------------------------------------------------

  belongs_to :related, polymorphic: true
  belongs_to :workshop, optional: true

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
    :group_status,
    to: :related_first_child,
    prefix: true,
    allow_nil: true

  # ---------------------------------------------------------------------------
  # scope
  # ---------------------------------------------------------------------------

  scope :other_events, -> { where(type: "Events::OtherEvent") }
  scope :survey_responses, -> { where(type: "Events::SurveyResponse") }
  scope :text_messages, -> { where(type: "Events::TextMessage") }
  scope :text_messages_send_by_app, -> { where(type: "Events::TextMessage", originated_by_app: true) }
  scope :text_messages_send_by_parent, -> { where(type: "Events::TextMessage", originated_by_app: false) }
  scope :sent_by_app_text_messages, -> { where(type: "Events::TextMessage", originated_by_app: true) }
  scope :received_text_messages, -> { where(type: "Events::TextMessage", originated_by_app: false) }
  scope :workshop_participations, -> { where(type: "Events::WorkshopParticipation") }

  # ---------------------------------------------------------------------------
  # scopes
  # ---------------------------------------------------------------------------

  # this cannot be named related_first_child_... due to Ransack behavior
  def self.parent_first_child_group_id_in(*v)
    where(related: Parent.first_child_group_id_in(v))
  end

  def self.parent_first_child_supporter_id_in(*v)
    where(related: Parent.first_child_supported_by(v))
  end

  # ---------------------------------------------------------------------------
  # helpers
  # ---------------------------------------------------------------------------

  def is_received_text_message?
    is_a?(Events::TextMessage) && !originated_by_app
  end

  def is_sent_by_app_text_message?
    is_a?(Events::TextMessage) && originated_by_app
  end

  # ---------------------------------------------------------------------------
  # ransack
  # ---------------------------------------------------------------------------

  def self.ransackable_scopes(auth_object = nil)
    %i[parent_first_child_group_id_in parent_first_child_supporter_id_in]
  end

end
