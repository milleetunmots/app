module Calendly
  class FetchScheduledEventService < Calendly::ApiBase

    SCHEDULED_EVENTS_ENDPOINT = '/scheduled_events'.freeze

    attr_reader :errors, :event_data

    def initialize(event_uri:)
      @errors = []
      @event_uri = event_uri
    end

    def call
      if @event_uri.blank?
        @errors << { message: "L'URI de l'événement calendly est requis" }
        return self
      end

      response = http_client_with_auth.get(@event_uri)
      status = response.status
      body = JSON.parse(response.body)

      if status.success?
        @event_data = parse_event_data(body['resource'])
      else
        @errors << {
          message: "Échec de la récupération de l'événement",
          details: body['message'] || body['title'],
          event_uri: @event_uri
        }
      end

      self
    end

    private

    def parse_event_data(resource)
      start_time = Time.zone.parse(resource['start_time'])
      end_time = Time.zone.parse(resource['end_time'])
      duration_minutes = ((end_time - start_time) / 60).to_i

      {
        start_time: start_time,
        end_time: end_time,
        duration_minutes: duration_minutes,
        event_type_uri: resource['event_type'],
        event_type_name: resource['name'],
        status: resource['status'],
        location: resource.dig('location', 'location'),
        created_at: resource['created_at'],
        updated_at: resource['updated_at']
      }
    end
  end
end
