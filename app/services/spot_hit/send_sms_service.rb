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
      'smslong' => 1
    }

    if @recipients.class == Array
      form.delete('destinataires_type')
      form['destinataires'] = Parent.where(id: @recipients).pluck(:phone_number).join(', ')
    else
      @recipients.each do |parent_id, keys|
        parent = Parent.find(parent_id)
        keys.each { |key, value| form.store("destinataires[#{parent.phone_number}][#{key}]", value) }
      end
    end
    
    response = HTTP.post(uri, form: form)
    if JSON.parse(response.body.to_s).key? 'erreurs'
      @errors << "Erreur lors de la programmation de la campagne. [Réponse SPOT_HIT API #{response.body.to_s}]"
    else
      create_events(JSON.parse(response.body.to_s)['id'])
    end
    self
  end

  private

  def create_events(message_id)
    @recipients.each do |parent_id, keys|
      parent = Parent.find(parent_id)
      event_params = {
        related_id: parent_id,
        related_type: 'Parent',
        body: @message,
        spot_hit_message_id: message_id,
        spot_hit_status: 0,
        type: 'Events::TextMessage',
        occurred_at: Time.at(@planned_timestamp)
      }
      keys.map { |key, value| event_params[:body].gsub!("{#{key}}", value) } if @recipients.class == Hash
      event = Event.create(event_params)
      @errors << "Erreur lors de la création de l\'event d\'envoi de sms pour #{parent.phone_number}." if event.errors.any?
    end
  end
end
