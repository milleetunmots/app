class SpotHit::SendRcsService

  URL = URI('https://www.spot-hit.fr/api/envoyer/rcs')

  attr_reader :errors

  def initialize(recipients:, planned_timestamp: Time.zone.now, media_id: nil, fallback_message: nil)
    @recipients = recipients
    @planned_timestamp = planned_timestamp
    @form = {
      'key' => ENV['SPOT_HIT_API_KEY'],
      'agent_id' => ENV['SPOT_HIT_AGENT_ID'],
      'media_id' => media_id,
      'fallback_message' => fallback_message
    }
    @errors = []
  end

  def call
    send_rcs
  end

  protected

  def send_rcs
    @form['date'] = Time.zone.now if Time.zone.at(@planned_timestamp).past?
    response = HTTP.post(URL, form: @form.merge({ 'date' => Time.zone.at(@planned_timestamp).past? ? (Time.zone.now + 1.minute).strftime('%Y-%m-%d %H:%M:%S') : Time.zone.at(@planned_timestamp).strftime('%Y-%m-%d %H:%M:%S') }))
    response = JSON.parse(response.body.to_s)
    if response['success']
      # create_events(response['id'])
      p response['id']
    else
      @errors << "Erreur lors de la programmation de la campagne : #{response['error']['message']}]"
    end
  end

  # def create_events(rcs_id)
  #
  # end
end
