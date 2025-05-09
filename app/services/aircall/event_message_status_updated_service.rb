module Aircall
  class EventMessageStatusUpdatedService < Aircall::ApiBase

    attr_reader :errors

    def initialize(payload:)
      @errors = []
      @message_id = payload['id']
      @event = Event.find_by(aircall_message_id: @message_id)
      @status = payload['status'] == 'delivered' ? 1 : 4
    end

    def call
      return self unless @event

      @errors << { message: 'La mise à jour du status du message a échoué', event_id: @event.id } unless @event.update(spot_hit_status: @status)
      self
    end
  end
end
