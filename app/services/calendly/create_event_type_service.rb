module Calendly
  class CreateEventTypeService < Calendly::ApiBase

    attr_reader :errors

    def initialize(owner:, name:, phone_number:)
      @errors = []
      @supporter_link = owner
      @name = name
      @supporter_phone_number = phone_number
    end

    def call
      response = http_client_with_auth.post(
        build_url(EVENT_TYPES_ENDPOINT),
        json: {
          active: true,
          owner: @supporter_link,
          name: @name,
          locations: [{
            kind: 'inbound_call',
            phone_number: @supporter_phone_number
          }],
          locale: 'fr'
        }
      )
      @errors << { message: "La création de l'event type a échoué : #{response.status.reason}", status: response.status.to_i } unless response.status.success?
      self
    end
  end
end
