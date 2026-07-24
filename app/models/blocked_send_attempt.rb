# == Schema Information
#
# Table name: blocked_send_attempts
#
#  id              :bigint           not null, primary key
#  detected_values :string           default([]), not null, is an Array
#  kind            :string           not null
#  message_body    :text             not null
#  provider        :string           not null
#  replay_params   :jsonb            not null
#  resolved_at     :datetime
#  status          :string           default("pending"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_blocked_send_attempts_on_status  (status)
#
class BlockedSendAttempt < ApplicationRecord

  KINDS = %w[url].freeze
  # not_blocked : détecté en mode surveillance (URL_FILTER_BLOCKING_ENABLED absent), le message a quand même
  # été transmis au provider — ne devrait pas être relancé puisqu'il n'a jamais été réellement bloqué.
  STATUSES = %w[pending relaunched not_blocked].freeze

  validates :provider, presence: true
  validates :kind, inclusion: { in: KINDS }
  validates :detected_values, presence: true
  validates :message_body, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :pending, -> { where(status: 'pending') }

  def relaunch!
    service = SendAttemptReplayer.new(self).call
    return service if service.errors.any? # re-bloqué : statut inchangé

    update!(status: 'relaunched', resolved_at: Time.zone.now)
    service
  end
end
