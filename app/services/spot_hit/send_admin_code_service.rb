class SpotHit::SendAdminCodeService < SpotHit::SendSmsService

  protected

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
