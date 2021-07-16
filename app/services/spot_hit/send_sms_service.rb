class SpotHit::SendSmsService

  attr_reader :errors

  def initialize(recipient_phone_numbers, planned_timestamp, message)
    @planned_timestamp = planned_timestamp
    @recipient_phone_numbers = recipient_phone_numbers
    @message = message
    @errors = []
  end
  
  def call
    uri = URI('https://www.spot-hit.fr/api/envoyer/sms')
  
    response = HTTP.post(uri, form: {
      key: ENV["SPOT_HIT_API_KEY"],
      destinataires: @recipient_phone_numbers.join(', '),
      message: @message,
      date: @planned_timestamp
    })
    @errors << 'Erreur lors de la programmation de la campagne.' if JSON.parse(response.body.to_s).key? 'erreurs'
    self
  end
end
