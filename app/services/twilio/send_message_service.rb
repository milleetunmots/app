require 'twilio-ruby'

class Twilio::SendMessageService
  attr_reader :errors, :message

  def initialize(to:, body:, media_url:)
    @client = Twilio::REST::Client.new(ENV['TWILIO_ACCOUNT_SID'], ENV['TWILIO_AUTH_TOKEN'])
    @to = to
    @body = body
    @media_url = media_url
    @errors = []
    @message = nil
  end

  def call
    begin
      @message =
        if @media_url.blank?
          @client.api.v2010.messages.create(
            body: @body,
            messaging_service_sid: ENV['TWILIO_MESSAGING_SID'],
            to: @to
          )
        else
          @client.api.v2010.messages.create(
            body: @body,
            messaging_service_sid: ENV['TWILIO_MESSAGING_SID'],
            to: @to,
            media_url: [@media_url]
          )
        end
    rescue Twilio::REST::RestError => e
      @errors << "Impossible d'envoyer le message"
    end
    self
  end
end
