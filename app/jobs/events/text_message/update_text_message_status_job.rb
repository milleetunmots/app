module Events
  class TextMessage
    class UpdateTextMessageStatusJob < ApplicationJob
      def perform(message_id_from_spot_hit, status)
        Event::UpdateTextMessageStatusService.new(message_id_from_spot_hit: message_id_from_spot_hit, status: status).call
      end
    end
  end
end
