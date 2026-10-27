# Point d'entrée unique des services d'envoi : exécute tous les contrôles de
# contenu (URLs, mots-clés, numéros de téléphone) en un appel. Un futur kind s'ajoute
# à GUARD_CLASSES sans toucher aux services d'envoi.
class BlockedSendAttempt::SendGuard

  # Volontairement générique : ne jamais révéler quel contrôle a déclenché ni
  # quelles valeurs — un attaquant affinerait sinon son message par essais
  # successifs. Le détail reste dans BlockedSendAttempt (super_admin).
  BLOCKED_MESSAGE = "Ce message n'a pas pu être envoyé : le pôle tech va le vérifier. Vous serez prévenu(e) dans vos tâches dès que ce sera fait.".freeze

  GUARD_CLASSES = [BlockedSendAttempt::UrlSendGuard, BlockedSendAttempt::KeywordSendGuard, BlockedSendAttempt::PhoneNumberSendGuard].freeze

  # Nombre de destinataires de l'envoi, pour l'alerte de l'équipe tech : il
  # n'est pas stocké sur la tentative, replay_params ne portant que des tags,
  # groupes ou enfants. nil quand il n'y a pas de destinataire (modèle RCS).
  attr_reader :recipients_count

  # Tentatives « à traiter » tracées par register! : un appelant qui diffère le
  # signalement les signale lui-même après son rollback.
  attr_reader :blocked_attempts

  # admin_user_id : auteur d'un envoi manuel, nil pour un envoi automatique.
  # defer_report : l'envoi a lieu dans une transaction que l'appelant peut
  # annuler (création d'atelier) ; tâche et alerte Slack n'y sont pas émises.
  def initialize(text, provider:, extra_texts: [], replay_params: {}, blocked_send_attempt_id: nil, admin_user_id: nil, recipients_count: nil, defer_report: false)
    @recipients_count = recipients_count
    @defer_report = defer_report
    @blocked_attempts = []

    # Garde explicite : sur le chemin nominal (pas de relance), l'id est nil
    # et cette requête serait exécutée en pure perte à chaque envoi.
    replayed_attempt = BlockedSendAttempt.find_by(id: blocked_send_attempt_id) if blocked_send_attempt_id.present?

    # Relance forcée par un super_admin : le contenu a été relu dans l'admin,
    # tous les contrôles sont neutralisés. À l'inverse, un id transmis sans
    # force_send (mode surveillance) doit continuer à bloquer normalement :
    # les variables destinataires, scannées seulement au niveau du provider,
    # peuvent révéler une cause absente au moment du premier scan.
    @bypass = replayed_attempt&.force_send || false

    # Hors relance forcée, seul le guard du kind de l'attempt rejoué est
    # suppressé : l'autre contrôle doit pouvoir tracer une cause nouvelle.
    replayed_kind = replayed_attempt&.kind

    @guards = GUARD_CLASSES.map do |guard_class|
      guard_class.new(
        text,
        provider: provider,
        extra_texts: extra_texts,
        replay_params: replay_params,
        blocked_send_attempt_id: (blocked_send_attempt_id if guard_class.kind == replayed_kind),
        admin_user_id: admin_user_id
      )
    end
  end

  def blocked?
    return false if @bypass

    @guards.any?(&:blocked?)
  end

  def block_send?
    return false if @bypass

    @guards.any?(&:block_send?)
  end

  def register!
    return [] if @bypass

    attempts = @guards.select(&:blocked?).filter_map(&:register!)
    @blocked_attempts = attempts.select { |attempt| attempt.persisted? && attempt.status == 'pending' }
    report unless @defer_report
    attempts
  end

  # Suivi de l'URL de la tâche quand register! en a créé ou retrouvé une, pour
  # que l'auteur la retrouve : à appeler après register!.
  def error_message
    [BLOCKED_MESSAGE, task_url].compact.join(' ')
  end

  private

  def report
    service = BlockedSendAttempt::ReportService.new(attempts: @blocked_attempts, recipients_count: @recipients_count).call
    Rollbar.error('BlockedSendAttempt::ReportService', errors: service.errors) if service.errors.any?
    @task = service.task
  end

  # Le lien ne doit jamais empêcher le blocage : sans DEFAULT_HOSTNAME, les
  # helpers `_url` lèvent (cf. SmsSendRecord::QuotaGuard#slack_link).
  def task_url
    return unless @task

    Rails.application.routes.url_helpers.admin_task_url(@task)
  rescue StandardError => e
    Rollbar.error('BlockedSendAttempt::SendGuard lien de tâche', errors: [e.message])
    nil
  end
end
