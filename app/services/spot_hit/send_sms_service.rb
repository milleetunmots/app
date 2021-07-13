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
      'key' => ENV["HOT_SPOT_API_KEY"],
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
    @errors << 'Erreur lors de la programmation de la campagne.' if JSON.parse(response.body.to_s).key? 'erreurs'
    self
  end
end