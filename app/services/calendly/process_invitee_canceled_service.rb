module Calendly
  class ProcessInviteeCanceledService

    attr_reader :errors, :scheduled_call

    def initialize(payload:)
      @errors = []
      @payload = payload
      @invitee_payload = payload['payload'] || payload
    end

    def call
      find_scheduled_call
      return self if @errors.any?

      update_scheduled_call
      self
    end

    private

    def find_scheduled_call
      event_uri = @invitee_payload['event']

      unless event_uri
        @errors << { message: "L'URI de l'événement est manquant dans le payload" }
        return
      end

      @scheduled_call = ScheduledCall.find_by(calendly_event_uri: event_uri)

      return if @scheduled_call

      @errors << {
        message: 'Aucun ScheduledCall trouvé pour cet événement',
        event_uri: event_uri
      }
    end

    def update_scheduled_call
      cancellation = @invitee_payload['cancellation'] || {}
      cancellation_reason = cancellation['reason'] || cancellation['canceler_type']

      canceled_at = if cancellation['canceled_at'].present?
                      Time.zone.parse(cancellation['canceled_at'])
                    else
                      Time.zone.now
                    end

      @scheduled_call.assign_attributes(
        status: 'canceled',
        canceled_at: canceled_at,
        cancellation_reason: cancellation_reason,
        raw_payload: @payload
      )

      return if @scheduled_call.save

      @errors << {
        message: 'Échec de la mise à jour du ScheduledCall',
        validation_errors: @scheduled_call.errors.full_messages
      }
    end
  end
end
