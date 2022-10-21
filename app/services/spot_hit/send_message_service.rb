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
    sending = HTTP.post(uri, form: form)
    @response = JSON.parse(sending.body.to_s)

    if @response.key? "erreurs"
      @errors << "Code d'erreur: #{@response["erreurs"]}"
    else
      get_receipts
      create_events
    end
  end

  def get_receipts
    uri = URI("https://www.spot-hit.fr/api/dlr")
    form = {
      "key" => ENV["SPOT_HIT_API_KEY"],
      "id" => @response["id"]
    }
    @receipts = HTTP.post(uri, form: form)
    @receipts = JSON.parse(@receipts.body.to_s)

    loop do
      @receipts = HTTP.post(uri, form: form)
      @receipts = JSON.parse(@receipts.body.to_s)

      break if @receipts.instance_of?(Array)
    end
    byebug
  end

  def create_events
    recipients = @recipients
    recipients = {recipients => {}} if recipients.instance_of?(Integer)
    recipients.each do |parent_id, keys|
      parent = Parent.find(parent_id)
      @receipts.each do |receipt|
        next unless receipt[0] == parent.phone_number

        event_params = {
          related_id: parent_id,
          related_type: "Parent",
          body: @message,
          spot_hit_message_id: receipt[5],
          spot_hit_status: receipt[1],
          type: "Events::TextMessage",
          occurred_at: Time.at(@planned_timestamp)
        }
        keys&.map { |key, value| event_params[:body].gsub!("{#{key}}", value) }
        Event.create(event_params)
      end
    end
  end
end
