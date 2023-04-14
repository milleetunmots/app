module Events
  class TextMessage

    class RemoveUnprogrammedJob < ApplicationJob

      def perform
        Events::TextMessage.sent_by_app_text_messages.where(spot_hit_status: 0).find_each do |text_message|
          params = {
            key: ENV['SPOT_HIT_API_KEY'],
            id: text_message.spot_hit_message_id,
            date_start: text_message.occured_at.prev_day.to_i,
            date_end: text_message.occured_at.next_day.to_i
          }
          check = spothit_check(params.merge(product: 'sms')) || spothit_check(params.merge(product: 'mms'))
          text_message.destroy if check.nil?
        end
      end

      def spothit_check(params)
        raw_response = HTTP.get('https://www.spot-hit.fr/api/campaign/list', params: params)
        response = JSON.parse(raw_response.body.to_s)
        if response.key? 'erreurs'
          raise "Error: #{response.body}]"
        elsif response.size.zero?
          nil
          # response looks like
          # [ [ "245174", "test2", "", "1", "1681370520", "0", "", "sms", "1681284185", "+33637572453" ] ]
          # so an empty array means the message does not exist in spothit
        else
          response.first
        end
      end
    end
  end
end
