module Calendly
  class CreateEventTypeService < Calendly::ApiBase

    attr_reader :errors

    def initialize(name:, calendly_user_uri:, aircall_phone_number:)
      @errors = []
      @calendly_user_uri = calendly_user_uri
      @aircall_phone_number = aircall_phone_number
      @event_type_name = name
    end

    def call
      user = AdminUser.find_by(aircall_phone_number: @aircall_phone_number, calendly_user_uri: @calendly_user_uri)
      unless user
        @errors << { message: "L'accompagnante n'a pas été trouvée",
                     aircall_phone_number: @aircall_phone_number,
                     calendly_user_uri: @calendly_user_uri }
        return self
      end
      response = http_client_with_auth.post(
        build_url(EVENT_TYPES_ENDPOINT),
        json: {
          active: true,
          owner: @calendly_user_uri,
          name: @event_type_name,
          locations: [{
            kind: 'inbound_call',
            phone_number: @aircall_phone_number
          }],
          locale: 'fr'
        }
      )
      status = response.status
      response = JSON.parse(response.body)
      if status.success?
        user.update(calendly_scheduling_url: response['resource']['scheduling_url'])
      else
        @errors << { message: "La création de l'event type a échoué", details: response['details'] }
      end
      self
    end
  end
end
