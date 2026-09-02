# Point d'entrée unique des services d'envoi : exécute tous les contrôles de
# contenu (URLs, mots-clés, numéros de téléphone) en un appel. Un futur kind s'ajoute
# à GUARD_CLASSES sans toucher aux services d'envoi.
class BlockedSendAttempt::SendGuard

  # Volontairement générique : ne jamais révéler quel contrôle a déclenché ni
  # quelles valeurs — un attaquant affinerait sinon son message par essais
  # successifs. Le détail reste dans BlockedSendAttempt (super_admin).
  BLOCKED_MESSAGE = 'Ce message ne peut pas être envoyé, veuillez contacter le pôle tech.'.freeze

  GUARD_CLASSES = [BlockedSendAttempt::UrlSendGuard, BlockedSendAttempt::KeywordSendGuard, BlockedSendAttempt::PhoneNumberSendGuard].freeze

  def initialize(text, provider:, extra_texts: [], replay_params: {}, blocked_send_attempt_id: nil)
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
        blocked_send_attempt_id: (blocked_send_attempt_id if guard_class.kind == replayed_kind)
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

    @guards.select(&:blocked?).filter_map(&:register!)
  end

  def error_message
    BLOCKED_MESSAGE
  end
end
