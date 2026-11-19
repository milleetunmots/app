class BlockedSendAttempt::SendAttemptReplayer

  # Message transmis au service rejoué, après la normalisation qu'il y applique
  # en place (jeton Typeform, variables Aircall) : le même texte qu'un envoi
  # direct aurait enregistré dans la case PM.
  attr_reader :message

  def initialize(blocked_send_attempt)
    @attempt = blocked_send_attempt
  end

  def call
    params = @attempt.replay_params.symbolize_keys
    @message = params[:message]
    service_class(params).new(
      params[:planned_date],
      params[:planned_hour],
      params[:recipients],
      @message,
      params[:rcs_media_id],
      params[:redirection_target_id],
      params[:quit_message],
      params[:workshop_id],
      params[:supporter],
      params[:group_status],
      params[:provider],
      params[:aircall_number_id],
      blocked_send_attempt: @attempt
    ).call
  end

  private

  # Une invitation d'atelier doit être rejouée par le service qui l'a envoyée :
  # lui seul remplit {RESPONSE_LINK} et écarte les parents exclus des ateliers.
  # Rejouée par ProgramMessageService, elle partait sans aucune variable et
  # Spot-Hit la rejetait faute de destinataire.
  def service_class(params)
    params[:workshop_id].present? ? Workshop::ProgramWorkshopInvitationService : ProgramMessageService
  end
end
