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

    if @recipients.class == Array
      form.delete("destinataires_type")
      form["destinataires"] = Parent.where(id: @recipients).pluck(:phone_number).join(", ")
    else
      @recipients.each do |parent_id, keys|
        parent = Parent.find(parent_id)
        keys.each { |key, value| form.store("destinataires[#{parent.phone_number}][#{key}]", value) }
      end
    end

    response = HTTP.post(uri, form: form)
    if JSON.parse(response.body.to_s).key? "erreurs"
      @errors << "Erreur lors de la programmation de la campagne. [Réponse SPOT_HIT API #{response.body.to_s}]"
    else
      create_events(JSON.parse(response.body.to_s)["id"])
    end
    self
  end
end
