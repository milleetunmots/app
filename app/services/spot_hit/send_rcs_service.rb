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
    @message = fallback_message
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
      # form params: custom_list_with_data[phone][variable]=value
      # same format as SMS with data but with custom_list_with_data instead of destinataires
      @recipients.each do |phone, variables|
        variables.each do |key, value|
          @form["custom_list_with_data[#{phone}][#{key}]"] = value
        end
      end
    end
    @form['date'] = Time.zone.now if Time.zone.at(@planned_timestamp).past?
    response = HTTP.post(
      URL,
      form: @form.merge({ 'date' => Time.zone.at(@planned_timestamp).past? ? 1.minute.from_now.strftime('%Y-%m-%d %H:%M:%S') : Time.zone.at(@planned_timestamp).strftime('%Y-%m-%d %H:%M:%S') })
    )
    response = JSON.parse(response.to_s)
    if response['success']
      create_events(response['campaign_id'])
    else
      @errors << "Erreur lors de la programmation de la campagne : #{response['error']['message']}]"
    end
  end

  def create_events(rcs_id)
    recipients = @recipients
    if recipients.first.is_a?(String)
      recipients = recipients.split(', ').to_h { |phone| [phone, {}] }
    end
    recipients.each do |phone_number, keys|
      parent = Parent.find_by!(phone_number: phone_number)
      event_attributes = {
        related_id: parent.id,
        related_type: 'Parent',
        body: @message.dup,
        spot_hit_rcs_id: rcs_id,
        spot_hit_status: 0,
        type: 'Events::TextMessage',
        occurred_at: Time.at(@planned_timestamp)
      }
      keys&.map { |key, value| event_attributes[:body].gsub!("{#{key}}", value.to_s) }
      event = Event.create(event_attributes)
      @errors << "Erreur lors de la création de l'event d'envoi de rcs pour #{parent.phone_number}." if event.errors.any?
    end
  end
end
