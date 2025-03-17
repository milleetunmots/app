module Aircall
  class SendMessageService < Aircall::ApiBase
    attr_reader :errors

    def initialize(number_id:, to:, body:)
      @errors = []
      @number_id = number_id
      @to = to
      @body = body
    end

    # TO DO : safeguard + event text message
    def call
      return self unless ENV['AIRCALL_ENABLED']
      @errors << "Envoi impossible à cause de paramètres invalides" and return self if @to.blank? || @number_id.blank?

      response = http_client_with_auth.post(build_url(NUMBERS_ENDPOINT, "/#{@number_id}/messages/native/send"), json: { to: Phonelib.parse(@to).e164, body: @body })
      @errors << { message: "L'envoi du message Aircall a échoué : #{response.status.reason}", status: response.status.to_i } unless response.status.success?
      self
    end
  end
end
