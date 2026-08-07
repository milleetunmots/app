class BlockedSendAttempt::SendAttemptReplayer

  def initialize(blocked_send_attempt)
    @attempt = blocked_send_attempt
  end

  def call
    params = @attempt.replay_params.symbolize_keys
    ProgramMessageService.new(
      params[:planned_date],
      params[:planned_hour],
      params[:recipients],
      params[:message],
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
end
