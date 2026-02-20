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

    if @recipients.instance_of?(Array)
      form.delete('destinataires_type')
      # Convert parent IDs to phone numbers if needed
      if @recipients.first.is_a?(Integer)
        @recipients = Parent.where(id: @recipients).pluck(:phone_number)
      end
      form['destinataires'] = @recipients.join(', ')
    elsif @recipients.instance_of?(String)
      form.delete('destinataires_type')
      form['destinataires'] = @recipients
    else
      @recipients.each do |parent_phone_number, keys|
        keys.each { |key, value| form.store("destinataires[#{parent_phone_number}][#{key}]", value) }
      end
    end

    send_message(uri, form)
    self
  end
end
