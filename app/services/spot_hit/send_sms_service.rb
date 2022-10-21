class SpotHit::SendSmsService < SpotHit::SendMessageService
  def call
    uri = URI("https://www.spot-hit.fr/api/envoyer/sms")
    form = {
      "key" => ENV["SPOT_HIT_API_KEY"],
      "destinataires" => {},
      "message" => @message,
      "date" => @planned_timestamp,
      "destinataires_type" => "datas",
      "smslong" => 1
    }

    if @recipients.instance_of?(Array)
      form.delete("destinataires_type")
      form["destinataires"] = Parent.where(id: @recipients).pluck(:phone_number).join(", ")
    elsif @recipients.instance_of?(Integer)
      form.delete("destinataires_type")
      form["destinataires"] = Parent.find(@recipients).phone_number
    else
      @recipients.each do |parent_id, keys|
        parent = Parent.find(parent_id)
        keys.each { |key, value| form.store("destinataires[#{parent.phone_number}][#{key}]", value) }
      end
    end

    send_message(uri, form)
    self
  end
end
