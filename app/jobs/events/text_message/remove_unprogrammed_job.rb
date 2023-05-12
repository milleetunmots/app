module Events
  class TextMessage

    class RemoveUnprogrammedJob < ApplicationJob

      def perform
        Events::TextMessage.sent_by_app_text_messages.where(spot_hit_status: 0).find_each do |text_message|
          params = {
            key: ENV['SPOT_HIT_API_KEY'],
            id: text_message.spot_hit_message_id,
            date_start: text_message.occurred_at.prev_day.to_i,
            date_end: text_message.occurred_at.next_day.to_i
          }
          check = spothit_check(params.merge(product: 'sms')) || spothit_check(params.merge(product: 'mms'))
          if check.nil?
            text_message.destroy
          else
            status =
              case check[5].to_i
              when 0
                0
              when 1
                3
              when 2
                2
              when 3
                4
              end
            text_message.spot_hit_status = status
            text_message.save(validate: false)
          end
          sleep(1)
        rescue StandardError => e
          next
        end
      end

      def spothit_check(params)
        raw_response = HTTP.get('https://www.spot-hit.fr/api/campaign/list', params: params)
        response = JSON.parse(raw_response.body.to_s)
        if response.is_a?(Hash) && response.key?('erreurs')
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
