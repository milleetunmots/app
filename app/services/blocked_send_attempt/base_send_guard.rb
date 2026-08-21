# Invariants communs aux guards d'envoi (URL, mots-clés) : scan du message +
# extra_texts, mode surveillance vs blocage par flag ENV, trace dans
# BlockedSendAttempt avec déduplication anti-retry Sidekiq.
# Les sous-classes définissent : self.kind, self.blocking_enabled?, detected_values.
class BlockedSendAttempt::BaseSendGuard

  # extra_texts : contenus scannés en plus du message mais non stockés comme
  # message_body — typiquement les valeurs des variables destinataires SpotHit.
  def initialize(text, provider:, extra_texts: [], replay_params: {}, blocked_send_attempt_id: nil)
    @text = text
    @extra_texts = extra_texts
    @provider = provider
    @replay_params = replay_params
    @blocked_send_attempt_id = blocked_send_attempt_id
  end

  delegate :kind, to: :class

  def blocked?
    detected_values.any?
  end

  # Tant que le flag de blocage n'est pas activé, on se contente de tracer
  # la tentative (via register!) sans empêcher l'envoi réel.
  def block_send?
    blocked? && self.class.blocking_enabled?
  end

  def register!
    return if @blocked_send_attempt_id.present?

    # Les jobs avec retry (Aircall::SendMessageJob, retry: 10) repassent ici à
    # chaque tentative après un échec API : on retrouve la tentative identique
    # déjà tracée plutôt que d'en créer une par retry.
    existing = BlockedSendAttempt
               .where(status: %w[pending not_blocked], provider: @provider, kind: kind, message_body: @text)
               .find_by(replay_params: @replay_params)
    return existing if existing

    # `create` et non `create!` : on est en plein chemin d'envoi, une trace
    # invalide (message vide…) ne doit pas faire échouer l'envoi lui-même.
    attempt = BlockedSendAttempt.create(
      provider: @provider,
      kind: kind,
      detected_values: detected_values,
      message_body: @text,
      replay_params: @replay_params,
      status: block_send? ? 'pending' : 'not_blocked'
    )
    Rollbar.error('BlockedSendAttempt non tracé', errors: attempt.errors.full_messages, provider: @provider, kind: kind) unless attempt.persisted?

    attempt
  end

  private

  def scannable_text
    @scannable_text ||= ([@text] + Array(@extra_texts)).map(&:to_s).join("\n")
  end
end
