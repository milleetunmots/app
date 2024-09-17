# == Schema Information
#
# Table name: events
#
#  id                        :bigint           not null, primary key
#  acceptation_date          :date
#  body                      :text
#  discarded_at              :datetime
#  is_support_module_message :boolean          default(FALSE), not null
#  occurred_at               :datetime
#  originated_by_app         :boolean          default(TRUE), not null
#  parent_presence           :string
#  parent_response           :string
#  related_type              :string
#  spot_hit_status           :integer
#  subject                   :string
#  type                      :string
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  quit_group_child_id       :bigint
#  related_id                :bigint
#  spot_hit_message_id       :string
#  workshop_id               :bigint
#
# Indexes
#
#  index_events_on_discarded_at                 (discarded_at)
#  index_events_on_quit_group_child_id          (quit_group_child_id)
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

  SPOT_HIT_STATUS = ['En attente', 'Livré', 'Envoyé', 'En cours', 'Echec', 'Expiré'].freeze
  PARENT_PRESENCES = %w[present planned_absence not_planned_absence queue].freeze

  # ---------------------------------------------------------------------------
  # relations
  # ---------------------------------------------------------------------------

  belongs_to :related, polymorphic: true
  belongs_to :workshop, optional: true
  belongs_to :quit_group_child, optional: true, class_name: :Child

  # ---------------------------------------------------------------------------
  # validations
  # ---------------------------------------------------------------------------

  validates :occurred_at, presence: true

  # ---------------------------------------------------------------------------
  # helpers
  # ---------------------------------------------------------------------------

  delegate :current_child, :security_code, to: :related, prefix: true, allow_nil: true
  delegate :id, :group, :group_id, :group_name, :group_status, to: :related_current_child, prefix: true, allow_nil: true

  # ---------------------------------------------------------------------------
  # scope
  # ---------------------------------------------------------------------------

  scope :other_events, -> { where(type: 'Events::OtherEvent') }
  scope :survey_responses, -> { where(type: 'Events::SurveyResponse') }
  scope :text_messages, -> { where(type: 'Events::TextMessage') }
  scope :sent_by_app_text_messages, -> { where(type: 'Events::TextMessage', originated_by_app: true) }
  scope :received_text_messages, -> { where(type: 'Events::TextMessage', originated_by_app: false) }
  scope :workshop_participations, -> { where(type: 'Events::WorkshopParticipation') }

  # ---------------------------------------------------------------------------
  # scopes
  # ---------------------------------------------------------------------------

  # this cannot be named related_current_child_... due to Ransack behavior
  def self.parent_current_child_group_id_in(*ids)
    where(related: Parent.current_child_group_id_in(ids))
  end

  def self.parent_current_child_supporter_id_in(*ids)
    where(related: Parent.current_child_supported_by(ids))
  end

  # ---------------------------------------------------------------------------
  # helpers
  # ---------------------------------------------------------------------------

  def received_text_message?
    is_a?(Events::TextMessage) && !originated_by_app
  end

  def sent_by_app_text_message?
    is_a?(Events::TextMessage) && originated_by_app
  end

  # ---------------------------------------------------------------------------
  # ransack
  # ---------------------------------------------------------------------------

  def self.ransackable_scopes(auth_object = nil)
    %i[parent_current_child_group_id_in parent_current_child_supporter_id_in]
  end
end
