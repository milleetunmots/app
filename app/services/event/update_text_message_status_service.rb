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
      update_text_message(@message_id_from_spot_hit, @status)
    end
  end

  private

  def check_message_id_from_spot_hit(id)
    Events::TextMessage.where(spot_hit_message_id: id).count > 1
  end

  def update_all_text_messages_of_campaign(campaign_id)
    uri = URI("https://www.spot-hit.fr/api/dlr")
    form = {
      "key" => ENV["SPOT_HIT_API_KEY"],
      "id" => campaign_id
    }
    @receipts = HTTP.post(uri, form: form)
    @receipts = JSON.parse(@receipts.body.to_s)

    result = @receipts.map { |receipt| {phone_number: receipt[0], status: receipt[1] } }

    Events::TextMessage.where(spot_hit_message_id: campaign_id).each do |message|
      receipt = result.find { |item| item[:phone_number] == message.related.phone_number }

      receipt.nil? ? message.update(spot_hit_status: receipt[1]) : message.update!(spot_hit_status: 4)
    end
  end

  def update_text_message(message_id, status)
    Events::TextMessage.find_by(spot_hit_message_id: message_id).update!(spot_hit_status: status)
  end

end

