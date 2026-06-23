class EventsController < ApplicationController
  skip_before_action :authenticate_admin_user!
  skip_before_action :verify_authenticity_token

  # Statut RCS Spot-Hit -> spot_hit_status de l'event (libellés : Event::SPOT_HIT_STATUS)
  # cf. https://doc.spot-hit.fr/api/suivi.html
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

  def index
    head :no_content
  end

  def create
    case params[:source]&.to_sym
    when :buzz
      service = CreateBuzzExpertEventService.new(
        phone_number: params[:phone],
        body: params[:response]
      ).call

      if service.errors.any?
        puts "CreateBuzzExpertEventService errors: #{service.errors}"
        head :unprocessable_entity
      else
        head :no_content
      end
    end
  end

  def update_status
    Events::TextMessage::UpdateTextMessageStatusJob.perform_later(params[:id_message], params[:statut])
    head :ok
  end

  def spot_hit_stop
    parsed_phone = Phonelib.parse(params[:numero])
    parents = Parent.where(phone_number: parsed_phone.e164)
    parents.each do |parent|
      event = Event.new({
        related: parent,
                        body: "STOP",
                        spot_hit_message_id: params[:id],
                        spot_hit_status: 1,
                        type: 'Events::TextMessage',
                        occurred_at: Time.at(params[:date].to_i),
                        originated_by_app: false
      })
      head :unprocessable_entity and return unless event.save
    end

    parents.each do |parent|
      parent.children.where.not(group_id: nil).where(group_status: %w[active paused]).each do |child|
        child.parent1 == parent ? child.should_contact_parent1 = false : child.should_contact_parent2 = false
        if child.should_contact_parent1 == false && child.should_contact_parent2 == false
          child.group_status = "stopped"
          child.group_end = Time.zone.now
        end
        child.save(validate: false)
      end
    end

    head :ok
  end

  def spot_hit_response
    parsed_phone = Phonelib.parse(params[:numero])
    event = Events::TextMessage.new(
      {
        related: Parent.find_by(phone_number: parsed_phone.e164),
        body: params[:message],
        spot_hit_message_id: params[:id],
        spot_hit_status: 1,
        occurred_at: Time.zone.at(params[:date].to_i),
        originated_by_app: false
      }
    )
    if event.save
      response_service = Event::SendMessageToParentResponseService.new(parsed_phone.e164).call
      if response_service.errors.any?
        Rollbar.error('Events::SendMessageToParentResponseService', parent_phone_number: parsed_phone.e164, errors: response_service.errors)
      end
      head :ok
    else
      head :unprocessable_entity
    end
  end

  def spot_hit_rcs_data
    payload = JSON.parse(request.raw_post)
    Array.wrap(payload['events']).each do |event|
      event_content = event['messageStatusChanged'] || event['userMessageReceived']
      unless event_content
        Rollbar.error("spot_hit_rcs_data: event without content", event: event)
        next
      end

      text_message_datas = retrieve_text_message_datas(event_content)
      handle_rcs_error(event_content, text_message_datas) if event_content['error']
      apply_rcs_status_change(event_content, text_message_datas) if event['messageStatusChanged']
      unless event['on']
        Rollbar.error('spot_hit_rcs_data: event without date', event: event)
        next
      end

      event_date = Time.zone.parse(event['on'])
      create_message_received_event(event_date, event_content, text_message_datas) if event['userMessageReceived']
    end

    head :ok
  rescue JSON::ParserError => e
    Rollbar.error('spot_hit_rcs_data: invalid payload JSON', message: e.message, request: request)
    head :bad_request
  end

  private

  def retrieve_text_message_datas(event_content)
    campaign_id = event_content.dig('context', 'campaign_id')
    unless campaign_id
      Rollbar.error('spot_hit_rcs_data: campaign_id not found', event_content: event_content)
      return {}
    end

    phone = Phonelib.parse(event_content['userId'].to_s.strip).e164
    parent = Parent.find_by(phone_number: phone)
    unless parent
      Rollbar.error('spot_hit_rcs_data: parent not found', event_content: event_content)
      return {}
    end
    {
      parent: parent,
      campaign_id: campaign_id,
      text_message: Events::TextMessage.find_by(spot_hit_rcs_id: campaign_id, related_type: 'Parent', related_id: parent.id)
    }
  end

  def handle_rcs_error(event_content, text_message_datas)
    return unless event_content['error']

    Rollbar.error('spot_hit_rcs_data: RCS delivery error', event_content: event_content)
    return if (text_message = text_message_datas[:text_message]).nil?

    text_message.rcs_error_code = event_content.dig('error', 'code')
    text_message.rcs_error_details = event_content.dig('error', 'details')
    Rollbar.error('spot_hit_rcs_data: failed to save error information', event_content: event_content, text_message: text_message) unless text_message.save
  end

  def apply_rcs_status_change(event_content, text_message_datas)
    status = event_content['status']
    unless status
      Rollbar.error('spot_hit_rcs_data: RCS status not found', event_content: event_content)
      return
    end

    spot_hit_status = RCS_STATUS_MAPPING[status]
    unless spot_hit_status
      Rollbar.error('spot_hit_rcs_data: unknown rcs status', event_content: event_content)
      return
    end
    return if spot_hit_status.zero?

    text_message = text_message_datas[:text_message]
    unless text_message
      Rollbar.error('spot_hit_rcs_data: text_message not found', event_content: event_content)
      return
    end

    attributes = { spot_hit_status: spot_hit_status }
    attributes[:is_fallback] = true if event_content['channelId'] == 'fallback'
    Rollbar.error('spot_hit_rcs_data: text_message not updated', event_content: event_content, text_message: text_message) unless text_message.update(attributes)
  end

  def create_message_received_event(date, event_content, text_message_datas)
    unless event_content['content']
      Rollbar.error('spot_hit_rcs_data: message received content not found', event_content: event_content)
      return
    end

    text = event_content.dig('content', 'text')
    unless text
      Rollbar.error('spot_hit_rcs_data: message received text not found', event_content: event_content)
      return
    end

    parent = text_message_datas[:parent]
    campaign_id = text_message_datas[:campaign_id]
    return if parent.blank? || campaign_id.blank?

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
