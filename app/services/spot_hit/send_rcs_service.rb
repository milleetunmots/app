class SpotHit::SendRcsService

  URL = URI('https://www.spot-hit.fr/api/envoyer/rcs')

  attr_reader :errors

  def initialize(recipients:, planned_timestamp: Time.zone.now, media_id: nil)
    @recipients = recipients
    @planned_timestamp = planned_timestamp
    @form = {
      'key' => ENV['SPOT_HIT_API_KEY'],
      'agent_id' => ENV['SPOT_HIT_AGENT_ID'],
      'media_id' => media_id,
      'fallback_message' => Media::TextMessagesBundle.find_body_by_rcs_media_id(media_id),
      'custom_list[]' => @recipients
    }
    @errors = []
  end

  def call
    send_rcs
  end

  protected

  def send_rcs
    @form['date'] = Time.zone.now if @planned_timestamp.past?
    response = HTTP.post(URL, form: @form.merge({'date' => @planned_timestamp.past? ? (Time.zone.now + 1.minute).strftime('%Y-%m-%d %H:%M:%S') : @planned_timestamp.now.strftime('%Y-%m-%d %H:%M:%S')}))
    response = JSON.parse(response.body.to_s)
    if response['success']
      create_events(response['id'])
    else
      @errors << "Erreur lors de la programmation de la campagne : #{response['error']['message']}]"
    end
  end
end
