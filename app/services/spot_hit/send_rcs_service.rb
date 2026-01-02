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
    self
  end

  protected

  def send_rcs
    if @recipients.first.is_a?(String)
      @form['custom_list[]'] = @recipients
    else
      @form['custom_list_with_data[]'] = @recipients
    end
    @form['date'] = Time.zone.now if Time.zone.at(@planned_timestamp).past?
    if Rails.env.development?
      ssl_ctx = OpenSSL::SSL::SSLContext.new
      ssl_ctx.verify_mode = OpenSSL::SSL::VERIFY_NONE
      response = HTTP.post(
        URL,
        form: @form.merge({ 'date' => Time.zone.at(@planned_timestamp).past? ? 1.minute.from_now.strftime('%Y-%m-%d %H:%M:%S') : Time.zone.at(@planned_timestamp).strftime('%Y-%m-%d %H:%M:%S') }),
        ssl_context: ssl_ctx
      )
    else
      response = HTTP.post(
        URL,
        form: @form.merge({ 'date' => Time.zone.at(@planned_timestamp).past? ? 1.minute.from_now.strftime('%Y-%m-%d %H:%M:%S') : Time.zone.at(@planned_timestamp).strftime('%Y-%m-%d %H:%M:%S') })
      )
    end
    if response['success']
      # create_events(response['id'])
    else
      @errors << "Erreur lors de la programmation de la campagne : #{response['error']['message']}]"
    end
  end

  # def create_events(rcs_id)
  #
  # end
end
