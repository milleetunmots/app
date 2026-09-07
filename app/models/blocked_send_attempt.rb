# == Schema Information
#
# Table name: blocked_send_attempts
#
#  id              :bigint           not null, primary key
#  detected_values :string           default([]), not null, is an Array
#  force_send      :boolean          default(FALSE), not null
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

  KINDS = %w[url keyword phone_number].freeze
  PROVIDERS = %w[spothit aircall].freeze
  # not_blocked : détecté en mode surveillance (URL_FILTER_BLOCKING_ENABLED absent), le message a quand même
  # été transmis au provider — ne devrait pas être relancé puisqu'il n'a jamais été réellement bloqué.
  STATUSES = %w[pending relaunched not_blocked].freeze

  validates :provider, inclusion: { in: PROVIDERS }
  validates :kind, inclusion: { in: KINDS }
  validates :detected_values, presence: true
  validates :message_body, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :pending, -> { where(status: 'pending') }
  scope :relaunched, -> { where(status: 'relaunched') }
  scope :not_blocked, -> { where(status: 'not_blocked') }

  # Les envois automatiques (Child::CreateService, SendCalendlyReminderJob…)
  # enregistrent leur tentative avec replay_params vide : le replayer rappellerait
  # ProgramMessageService avec des nils et planterait.
  def replayable?
    replay_params.present?
  end

  def relaunch!
    unless replayable?
      errors.add(:base, "Impossible de relancer : cette tentative provient d'un envoi automatique sans paramètres de relance.")
      return self
    end

    # Doit être persisté avant le replay : le blocage réel a lieu plus tard, dans
    # le job d'envoi, qui relit la tentative depuis la base via son id.
    update!(force_send: true)

    service = SendAttemptReplayer.new(self).call
    return service if service.errors.any? # échec pour une autre raison : statut inchangé

    update!(status: 'relaunched', resolved_at: Time.zone.now)
    resolve_other_attempts_for_same_message!
    service
  end

  private

  # Un même message peut être tracé deux fois (une URL ET un mot-clé détectés) :
  # la relance l'a envoyé une bonne fois pour toutes, l'autre tentative ne doit
  # pas rester « à traiter » indéfiniment.
  def resolve_other_attempts_for_same_message!
    self.class.pending
        .where(provider: provider, message_body: message_body, replay_params: replay_params)
        .where.not(id: id)
        .find_each { |attempt| attempt.update(status: 'relaunched', resolved_at: Time.zone.now) }
  end
end
