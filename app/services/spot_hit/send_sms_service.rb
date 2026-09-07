class SpotHit::SendSmsService < SpotHit::SendMessageService

  def call
    uri = URI('https://www.spot-hit.fr/api/envoyer/sms')
    form = {
      'key' => ENV['SPOT_HIT_API_KEY'],
      'destinataires' => {},
      'message' => @message,
      'date' => @planned_timestamp,
      'destinataires_type' => 'datas',
      'smslong' => 1
    }

    if personalized_recipients?
      recipient_variables.each do |parent_id, keys|
        phone_number = phone_numbers_by_parent_id[parent_id]
        next if phone_number.blank?

        keys.each { |key, value| form.store("destinataires[#{phone_number}][#{key}]", value) }
      end
    else
      form.delete('destinataires_type')
      form['destinataires'] = recipient_phone_numbers.join(', ')
    end

    send_message(uri, form)
    self
  end
end
