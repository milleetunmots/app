class Event::UpdateTextMessageStatusService

  include JsonResponseConcern

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
    response = HTTP.post(uri, form: form)
    @receipts = parse_json_response(response)

    # sans liste de reçus fiable, on ne touche à aucun statut : le fallback
    # `spot_hit_status: 4` plus bas passerait toute la campagne en échec
    return unless usable_receipts?(response, campaign_id)

    result = @receipts.map { |receipt| {phone_number: receipt[0], status: receipt[1] } }

    Events::TextMessage.where(spot_hit_message_id: campaign_id).each do |message|
      receipt = result.find { |item| message.related.present? && item[:phone_number] == message.related.phone_number }

      receipt.nil? ? message.update!(spot_hit_status: 4): message.update!(spot_hit_status: receipt[:status])
    end
  end

  def usable_receipts?(response, campaign_id)
    return true if @receipts.is_a?(Hash) && !@receipts.key?('erreurs')

    Rollbar.error(
      'Event::UpdateTextMessageStatusService: réponse DLR inexploitable',
      campaign_id: campaign_id,
      response: json_error_message(response, @receipts)
    )
    false
  end

  def update_text_message(message_id, status)
    Events::TextMessage.find_by(spot_hit_message_id: message_id)&.update!(spot_hit_status: status)
  end

end

