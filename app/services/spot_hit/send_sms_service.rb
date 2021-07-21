class SpotHit::SendSmsService

  attr_reader :errors

  def initialize(recipients, planned_timestamp, message)
    @planned_timestamp = planned_timestamp
    @recipients = recipients
    @message = message
    @errors = []
  end
  
  def call
    uri = URI('https://www.spot-hit.fr/api/envoyer/sms')
    form = {
      'key' => ENV["SPOT_HIT_API_KEY"],
      'destinataires' => {},
      'message' => @message,
      'date' => @planned_timestamp,
      'destinataires_type' => 'datas',
    }

    if @recipients.class == Array
      form.delete('destinataires_type')
      form['destinataires'] = @recipients.join(', ')
    else
      @recipients.each do |phone_number, keys|
        keys.map { |key, value| form.store("destinataires[#{phone_number}][#{key}]", value) }
      end
    end
    
    response = HTTP.post(uri, form: form)
    if JSON.parse(response.body.to_s).key? 'erreurs'
      @errors << 'Erreur lors de la programmation de la campagne.'
    else
      create_history(JSON.parse(response.body.to_s)['id'])
    end
    self
  end

  private

  def create_history message_id
    @recipients.each do |phone_number, keys|
      event_params = {
        related_id: Parent.where(phone_number: phone_number).first.id,
        related_type: 'Parent',
        body: @message,
        message_id: message_id,
        status: 0,
        type: 'Events::TextMessage',
        occurred_at: Time.at(@planned_timestamp)
      }
      keys.map { |key, value| event_params[:body].gsub!("{#{key}}", value) } if @recipients.class == Hash
      Event.create(event_params)
    end
  end
end
