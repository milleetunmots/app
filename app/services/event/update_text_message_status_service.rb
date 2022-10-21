class Event::UpdateTextMessageStatusService

  def initialize(message_id_from_spot_hit:, status:)
    @message_id_from_spot_hit = message_id_from_spot_hit
    @status = status
  end

  def call
    is_campaign_id = check_message_id_from_spot_hit(@message_id_from_spot_hit)
    if is_campaign_id
      update_all_text_messages_of_campaign(@message_id_from_spot_hit)
    else
      update_text_message(@message_id_from_spot_hit)
    end
  end

  private

  def check_message_id_from_spot_hit(id)

  end

  def update_all_text_messages_of_campaign(campagn_id)
    # uri = URI("https://www.spot-hit.fr/api/dlr")
    # form = {
    #   "key" => ENV["SPOT_HIT_API_KEY"],
    #   "id" => @response["id"]
    # }
    # @receipts = HTTP.post(uri, form: form)
    # @receipts = JSON.parse(@receipts.body.to_s)
  end

  def update_text_message(message_id)
    Events::TextMessage.find_by(spot_hit_message_id: @message_id_from_spot_hit).update!(spot_hit_status: @status)
  end

end

