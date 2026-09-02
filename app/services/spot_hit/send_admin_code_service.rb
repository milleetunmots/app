class SpotHit::SendAdminCodeService < SpotHit::SendSmsService

  protected

  # Contrairement aux messages destinés aux familles, un code 2FA cible un
  # AdminUser, qui n'a pas d'identifiant Parent. Ce service conserve donc son
  # contrat historique (un numéro brut) sans réautoriser ce format dans les
  # autres services Spot Hit.
  def personalized_recipients?
    false
  end

  def recipient_phone_numbers
    Array(@recipients).compact
  end

  # Le service parent utilise cette structure pour vérifier qu'il reste au
  # moins un destinataire. Ici les clés sont exceptionnellement les numéros eux-
  # mêmes : aucune résolution de Parent ni aucune création d'Event n'en découle.
  def recipient_variables
    recipient_phone_numbers.index_with { {} }
  end

  # Le safeguard standard filtre des IDs de parents. Pour la 2FA, on applique
  # directement la même liste blanche au numéro de l'administrateur.
  def restrict_recipients_to_safe_numbers!
    safe_numbers = ENV['SAFE_PHONE_NUMBERS'].to_s.split(',').map(&:strip)
    @recipients = recipient_phone_numbers.select { |phone| safe_numbers.include?(phone) }
  end

  # Le service parent résout un Parent à partir du numéro du destinataire et
  # crée un Event TextMessage contenant le corps du message. Un numéro de
  # parent n'est pas unique et le mobile d'un administrateur peut coïncider
  # avec celui d'une famille : sans cette surcharge, un code 2FA finirait
  # écrit dans l'historique de cette famille.
  def create_events(_message_id)
    nil
  end

  # Un SMS d'authentification ne doit jamais être bloqué ni retranscrit par un
  # filtre de contenu pensé pour les messages aux familles : un pattern
  # coïncidant avec le libellé du code verrouillerait tous les administrateurs
  # hors de l'application, et sa présence en clair dans BlockedSendAttempt
  # (message_body) violerait la confidentialité du code.
  def content_guard_enabled?
    false
  end
end
