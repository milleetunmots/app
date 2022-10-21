class SpotHit::SendMessageService

  attr_reader :errors

  def initialize(recipients, planned_timestamp, message, file = nil)
    @planned_timestamp = planned_timestamp
    @recipients = recipients
    @message = message
    @file = file
    @errors = []
  end

  protected

  def send_message(uri, form)
    response = HTTP.post(uri, form: form)
    if JSON.parse(response.body.to_s).key? "erreurs"
      @errors << "Erreur lors de la programmation de la campagne. [Réponse SPOT_HIT API #{response.body.to_s}]"
    else
      create_events(JSON.parse(response.body.to_s)["id"])
    end
  end

  def create_events(message_id)
    recipients = @recipients
    recipients = {recipients => {}} if recipients.instance_of?(Integer)
    recipients.each do |parent_id, keys|
      parent = Parent.find(parent_id)
      event_params = {
        related_id: parent_id,
        related_type: "Parent",
        body: @message,
        spot_hit_message_id: message_id,
        spot_hit_status: 0,
        type: "Events::TextMessage",
        occurred_at: Time.at(@planned_timestamp)
      }
      keys&.map { |key, value| event_params[:body].gsub!("{#{key}}", value) }
      event = Event.create(event_params)
      @errors << "Erreur lors de la création de l\'event d\'envoi de message pour #{parent.phone_number}." if event.errors.any?
      # @receipts.each do |receipt|
      #   next unless receipt[0] == parent.phone_number

      #   event_params = {
      #     related_id: parent_id,
      #     related_type: "Parent",
      #     body: @message,
      #     spot_hit_message_id: receipt[5],
      #     spot_hit_status: receipt[1],
      #     type: "Events::TextMessage",
      #     occurred_at: Time.at(@planned_timestamp)
      #   }
      #   keys&.map { |key, value| event_params[:body].gsub!("{#{key}}", value) }
      #   Event.create(event_params)
      # end
    end
  end
end
