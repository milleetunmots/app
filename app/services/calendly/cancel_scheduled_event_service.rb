module Calendly
  class CancelScheduledEventService < Calendly::ApiBase

    MAX_REASON_LENGTH = 10_000

    attr_reader :errors

    def initialize(event_uri:, reason: nil)
      @errors = []
      @event_uri = event_uri
      @reason = reason
    end

    def call
      if @event_uri.blank?
        @errors << { message: "L'URI de l'événement calendly est requis" }
        return self
      end

      response = http_client_with_auth.post(
        build_url(CANCELLATION_ENDPOINT.gsub('{uuid}', event_uuid)),
        json: build_request_body
      )
      status = response.status
      body = parse_json_body(response) || {}

      unless status.success?
        @errors << {
          message: "L'annulation de l'événement Calendly a échoué",
          details: body['message'] || body['title'] || response.body.to_s.truncate(500),
          event_uri: @event_uri
        }
      end

      self
    end

    private

    def event_uuid
      @event_uri.chomp('/').split('/').last
    end

    def build_request_body
      { reason: @reason&.slice(0, MAX_REASON_LENGTH) }.compact
    end
  end
end
