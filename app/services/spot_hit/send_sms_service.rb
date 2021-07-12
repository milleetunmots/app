class SpotHit::SendSmsService
  def initialize(recipient_phone_numbers, planned_timestamp, message)
    @planned_timestamp = planned_timestamp
    @recipient_phone_numbers = recipient_phone_numbers
    @message = message
  end
  
  def call
    uri = URI('https://www.spot-hit.fr/api/envoyer/sms')
  
    response = HTTP.post(uri, form: {
      key: ENV["HOT_SPOT_API_KEY"],
      destinataires: @recipient_phone_numbers.join(', '),
      message: @message,
      date: @planned_timestamp
    })
    return { error: 'Erreur lors de la programmation de la campagne.' } if JSON.parse(response.body.to_s).key? 'erreurs'
  end
end
