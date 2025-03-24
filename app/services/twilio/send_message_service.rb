require 'twilio-ruby'

class Twilio::SendMessageService
  attr_reader :errors

  def initialize(to:, body:)
    @client = Twilio::REST::Client.new(ENV['TWILIO_ACCOUNT_SID'], ENV['TWILIO_AUTH_TOKEN'])
    @to = to
    @body = body
    @errors = []
  end

  def call
    begin
      @client.messages.create(
        from: ENV['TWILIO_PHONE_NUMBER'],
        to: @to,
        body: @body
      )
    rescue Twilio::REST::RestError => e
      @errors << "Impossible d'envoyer le sms"
    end
    self
  end
end
