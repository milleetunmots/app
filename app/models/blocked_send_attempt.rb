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
#  admin_user_id   :bigint
#
# Indexes
#
#  index_blocked_send_attempts_on_admin_user_id  (admin_user_id)
#  index_blocked_send_attempts_on_status         (status)
#
# Foreign Keys
#
#  fk_rails_...  (admin_user_id => admin_users.id)
#
class BlockedSendAttempt < ApplicationRecord

  KINDS = %w[url keyword phone_number].freeze
  PROVIDERS = %w[spothit aircall].freeze
  # not_blocked : détecté en mode surveillance (URL_FILTER_BLOCKING_ENABLED absent), le message a quand même
  # été transmis au provider — ne devrait pas être relancé puisqu'il n'a jamais été réellement bloqué.
  # archived : clos par un super_admin sans relance, le message n'est jamais parti.
  STATUSES = %w[pending relaunched not_blocked archived].freeze

  RELAUNCH_REFUSED_MESSAGE = 'Seules les tentatives à traiter peuvent être relancées.'.freeze
  RELAUNCH_IN_PROGRESS_MESSAGE = 'Une relance de cet envoi est déjà en cours.'.freeze
  ARCHIVE_REFUSED_MESSAGE = 'Seules les tentatives à traiter peuvent être archivées.'.freeze

  # Auteur de l'envoi manuel ; nil pour un envoi automatique ou une tentative
  # antérieure à la colonne.
  belongs_to :admin_user, optional: true

  validates :provider, inclusion: { in: PROVIDERS }
  validates :kind, inclusion: { in: KINDS }
  validates :detected_values, presence: true
  validates :message_body, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :pending, -> { where(status: 'pending') }
  scope :relaunched, -> { where(status: 'relaunched') }
  scope :not_blocked, -> { where(status: 'not_blocked') }
  scope :archived, -> { where(status: 'archived') }
  # Un même envoi est tracé une fois par kind détecté (URL et mot-clé…) : ces
  # tentatives sœurs partagent provider, message et paramètres de relance.
  scope :same_message_as, ->(attempt) {
    where(provider: attempt.provider, message_body: attempt.message_body, replay_params: attempt.replay_params)
      .where.not(id: attempt.id)
  }

  # Valeurs ajoutées à la whitelist par la dernière relance, pour en rendre compte
  # à l'admin : vide tant que relaunch! n'a pas abouti, et pour un mot-clé.
  def whitelisted_values
    @whitelisted_values ||= []
  end

  # Les envois automatiques (Child::CreateService, SendCalendlyReminderJob…)
  # enregistrent leur tentative avec replay_params vide : le replayer rappellerait
  # ProgramMessageService avec des nils et planterait.
  def replayable?
    replay_params.present?
  end

  # admin_user : super_admin qui relance, renseigné comme ayant traité la tâche.
  def relaunch!(admin_user: nil)
    unless replayable?
      errors.add(:base, "Impossible de relancer : cette tentative provient d'un envoi automatique sans paramètres de relance.")
      return self
    end
    return self unless reserve_for_relaunch!

    service = replay_reserved_attempt
    if service.errors.any? # échec pour une autre raison : statut inchangé
      # La réservation est levée pour que l'envoi reste relançable ou archivable.
      update!(force_send: false)
      return service
    end

    update!(status: 'relaunched', resolved_at: Time.zone.now)
    siblings = resolve_other_attempts_for_same_message!
    # Après le replay seulement : si l'envoi avait échoué, la tentative reste à
    # traiter et la whitelist ne doit pas en garder la trace.
    @whitelisted_values = DetectedValuesWhitelister.new([self] + siblings).call
    resolve_task!(:relaunched, admin_user)
    service
  end

  # Clôt l'envoi sans le relancer : le message ne part jamais. Les tentatives
  # sœurs du même envoi sont archivées avec lui.
  def archive!(admin_user: nil)
    archived = with_lock do
      # force_send : une relance a réservé la tentative et le message est peut-être déjà parti.
      if status == 'pending' && !force_send
        update!(status: 'archived', resolved_at: Time.zone.now)
      else
        errors.add(:base, ARCHIVE_REFUSED_MESSAGE)
        false
      end
    end
    return self unless archived

    # `update` et non `update!`, comme pour la relance : la trace d'une sœur ne
    # doit pas faire échouer l'archivage déjà acté.
    self.class.pending.same_message_as(self).where(force_send: false).find_each do |sibling|
      sibling.update(status: 'archived', resolved_at: Time.zone.now)
    end
    resolve_task!(:archived, admin_user)
    self
  end

  private

  # Relance et archivage sont les deux issues d'une tentative « à traiter » : la
  # relance réserve la tentative sous verrou, une seconde relance (double-clic)
  # et l'archivage refusent ensuite une tentative réservée. force_send doit de
  # toute façon être persisté avant le replay : le blocage réel a lieu plus tard,
  # dans le job d'envoi, qui relit la tentative depuis la base via son id.
  def reserve_for_relaunch!
    with_lock do
      if status != 'pending'
        errors.add(:base, RELAUNCH_REFUSED_MESSAGE)
        false
      elsif force_send
        errors.add(:base, RELAUNCH_IN_PROGRESS_MESSAGE)
        false
      else
        update!(force_send: true)
      end
    end
  end

  # Une exception ne doit pas laisser la tentative réservée : elle ne serait plus
  # ni relançable ni archivable.
  def replay_reserved_attempt
    SendAttemptReplayer.new(self).call
  rescue StandardError
    update!(force_send: false)
    raise
  end

  # Prévient l'auteur. Le sort de l'envoi est déjà acté : un échec de la tâche
  # est rapporté, jamais remonté.
  def resolve_task!(outcome, admin_user)
    service = ResolveTaskService.new(attempt: self, outcome: outcome, admin_user: admin_user).call
    Rollbar.error('BlockedSendAttempt::ResolveTaskService', errors: service.errors) if service.errors.any?
  end

  # Un même message peut être tracé deux fois (une URL ET un mot-clé détectés) :
  # la relance l'a envoyé une bonne fois pour toutes, l'autre tentative ne doit
  # pas rester « à traiter » indéfiniment.
  #
  # Les tentatives résolues sont renvoyées : leurs valeurs détectées sont
  # whitelistées avec celles de la tentative relancée, sans quoi le numéro d'un
  # message autorisé pour son URL serait rebloqué au prochain envoi.
  def resolve_other_attempts_for_same_message!
    siblings = self.class.pending.same_message_as(self).to_a
    # `update` et non `update!` : le message est déjà parti, l'échec d'une trace
    # ne doit pas le faire remonter en erreur. Seules les sœurs réellement
    # résolues sont renvoyées : whitelister les valeurs d'une tentative restée
    # « à traiter » autoriserait un contenu que personne n'a validé.
    siblings.select { |attempt| attempt.update(status: 'relaunched', resolved_at: Time.zone.now) }
  end
end
