class Events::TextMessage

  class ProcessRcsDataJob < ApplicationJob
    queue_as :low

    RCS_STATUS_MAPPING = {
      'QUEUED' => 0,
      'DELIVERED' => 1,
      'SENT' => 2,
      'DELIVERY_RETRIED' => 3,
      'DELIVERY_FAILED' => 4,
      'READ' => 6,
      'SCHEDULE_QUEUED' => 0,
      'SCHEDULED' => 0,
      'SCHEDULE_DELETED' => 4,
      'SCHEDULE_DELETION_FAILED' => 4,
      'CLIENT_MESSAGE_INVALID' => 4,
      'CLIENT_CONFIGURATION_INVALID' => 4,
      'CLIENT_MESSAGE_EXPIRED' => 4,
      'CLIENT_QUOTA_EXCEEDED' => 4,
      'CLIENT_MESSAGE_FORBIDDEN' => 4,
      'CHANNEL_REJECTED' => 4,
      'CHANNEL_UNAVAILABLE' => 4,
      'CHANNEL_INTERNAL_ISSUE' => 4,
      'CHANNEL_OTHER_ISSUE' => 4,
      'USER_UKNOWN' => 4,
      'USER_BLOCKED' => 4,
      'USER_UNAVAILABLE' => 4,
      'INTERNAL_NOT_IMPLEMENTED' => 4,
      'INTERNAL_OTHER_ISSUE' => 4
      }.freeze

    def perform(payload)
      Array.wrap(payload['events']).each do |event|
        event_content = event['messageStatusChanged'] || event['userMessageReceived']
        unless event_content
          Rollbar.error('spot_hit_rcs_data: event without content', event: event)
          next
        end

        if event['messageStatusChanged']
          status = event_content['status']
          unless status
            Rollbar.error('spot_hit_rcs_data: RCS status not found', event_content: event_content)
            next
          end

          spot_hit_status = RCS_STATUS_MAPPING[status]
          unless spot_hit_status
            Rollbar.error('spot_hit_rcs_data: unknown rcs status', event_content: event_content)
            next
          end
          next if spot_hit_status.zero?

          text_message_datas = retrieve_text_message_datas(event_content)
          apply_rcs_status_change(event_content, text_message_datas, spot_hit_status)
        elsif event['userMessageReceived']
          unless event['on']
            Rollbar.error('spot_hit_rcs_data: event without date', event: event)
            next
          end

          text_message_datas = retrieve_text_message_datas(event_content)
          event_date = Time.zone.parse(event['on'])
          create_message_received_event(event_date, event_content, text_message_datas)
        else
          Rollbar.error('spot_hit_rcs_data: unknown event', event: event)
        end
      end
    end

    private

    def retrieve_text_message_datas(event_content)
      campaign_id = event_content.dig('context', 'campaign_id')
      unless campaign_id
        Rollbar.error('spot_hit_rcs_data: campaign_id not found', event_content: event_content)
        return {}
      end

      phone = Phonelib.parse(event_content['userId'].to_s.strip).e164
      if phone.blank?
        Rollbar.error('spot_hit_rcs_data: unparsable userId', event_content: event_content)
        return {}
      end

      parents = Parent.kept.where(phone_number: phone).order(:created_at)
      if parents.empty?
        Rollbar.error('spot_hit_rcs_data: parent not found', event_content: event_content)
        return {}
      end

      text_message = Events::TextMessage
                     .where(spot_hit_rcs_id: campaign_id, related_type: 'Parent', related_id: parents.map(&:id))
                     .order(:occurred_at)
                     .last

      {
        parent: text_message&.related || parents.last,
        campaign_id: campaign_id,
        text_message: text_message
      }
    end

    def apply_rcs_status_change(event_content, text_message_datas, spot_hit_status)
      text_message = text_message_datas[:text_message]
      unless text_message
        Rollbar.error('spot_hit_rcs_data: text_message not found', event_content: event_content)
        return
      end

      text_message_status = Event::SPOT_HIT_STATUS[text_message.spot_hit_status]
      event_status = Event::SPOT_HIT_STATUS[spot_hit_status]
      retrograde = Event::SPOT_HIT_STATUS_ORDERED.index(text_message_status) > Event::SPOT_HIT_STATUS_ORDERED.index(event_status)
      fallback_after_failure = event_content['channelId'] == 'fallback' && text_message_status == 'Échec'
      if retrograde && !fallback_after_failure
        Rollbar.error('spot_hit_rcs_data: retrograde rcs status',
                      event_content: event_content,
                      text_message_spot_hit_status: text_message.spot_hit_status,
                      event_status: spot_hit_status)
        return
      end

      attributes = { spot_hit_status: spot_hit_status }
      attributes[:is_fallback] = true if event_content['channelId'] == 'fallback'
      if event_content['error']
        Rollbar.error('spot_hit_rcs_data: RCS delivery error', event_content: event_content)
        attributes[:rcs_error_code] = event_content.dig('error', 'code')
      end
      Rollbar.error('spot_hit_rcs_data: text_message not updated', event_content: event_content, text_message: text_message) unless text_message.update(attributes)
    end

    def create_message_received_event(date, event_content, text_message_datas)
      parent = text_message_datas[:parent]
      campaign_id = text_message_datas[:campaign_id]
      return if parent.blank? || campaign_id.blank?

      unless event_content['content']
        Rollbar.error('spot_hit_rcs_data: message received content not found', event_content: event_content)
        return
      end

      text = event_content.dig('content', 'text')
      unless text
        Rollbar.error('spot_hit_rcs_data: message received text not found', event_content: event_content)
        return
      end

      text_message = Events::TextMessage.new(
        {
          related: parent,
          body: text,
          spot_hit_rcs_id: campaign_id,
          spot_hit_status: 1,
          occurred_at: date,
          originated_by_app: false
        }
      )
      Rollbar.error('spot_hit_rcs_data: message received text_message not created', event_content: event_content, errors: text_message.errors) unless text_message.save
    end
  end
end
