# == Schema Information
#
# Table name: scheduled_calls
#
#  id                   :bigint           not null, primary key
#  calendly_event_uri   :string           not null
#  calendly_invitee_uri :string
#  admin_user_id        :bigint
#  child_support_id     :bigint
#  parent_id            :bigint
#  call_session         :integer
#  scheduled_at         :datetime
#  duration_minutes     :integer
#  event_type_name      :string
#  event_type_uri       :string
#  invitee_email        :string
#  invitee_name         :string
#  invitee_comment      :text
#  status               :string           default("scheduled"), not null
#  canceled_at          :datetime
#  cancellation_reason  :text
#  raw_payload          :jsonb
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#
# Indexes
#
#  index_scheduled_calls_on_admin_user_id       (admin_user_id)
#  index_scheduled_calls_on_calendly_event_uri  (calendly_event_uri) UNIQUE
#  index_scheduled_calls_on_child_support_id    (child_support_id)
#  index_scheduled_calls_on_parent_id           (parent_id)
#  index_scheduled_calls_on_scheduled_at        (scheduled_at)
#  index_scheduled_calls_on_status              (status)
#
# Foreign Keys
#
#  fk_rails_...  (admin_user_id => admin_users.id)
#  fk_rails_...  (child_support_id => child_supports.id)
#  fk_rails_...  (parent_id => parents.id)
#

class ScheduledCall < ApplicationRecord

  STATUSES = %w[scheduled canceled].freeze

  belongs_to :admin_user, optional: true
  belongs_to :child_support, optional: true
  belongs_to :parent, optional: true

  validates :calendly_event_uri, presence: true, uniqueness: true
  validates :status, presence: true, inclusion: { in: STATUSES }

  scope :scheduled, -> { where(status: 'scheduled') }
  scope :canceled, -> { where(status: 'canceled') }
  scope :upcoming, -> { scheduled.where('scheduled_at >= ?', Time.zone.now) }
  scope :past, -> { where(scheduled_at: ..Time.zone.now) }

  def scheduled?
    status == 'scheduled'
  end

  def canceled?
    status == 'canceled'
  end

  def cancel!(reason: nil, canceled_at: Time.zone.now)
    update!(
      status: 'canceled',
      canceled_at: canceled_at,
      cancellation_reason: reason
    )
  end
end
