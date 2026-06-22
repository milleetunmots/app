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
    'SCHEDULE_DELETED' => 5,
    'SCHEDULE_DELETION_FAILED' => 4
  }.freeze

  # Zapper quand c'est QUEUE
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
      change = event['messageStatusChanged']
      apply_rcs_status_change(change) if change.present?
    end

    head :ok
  rescue JSON::ParserError => e
    Rollbar.error('spot_hit_rcs_data: payload JSON invalide', message: e.message, request: request)
    head :bad_request
  end

  private

  def apply_rcs_status_change(change)
    spot_hit_status = RCS_STATUS_MAPPING[change['status']]
    return if spot_hit_status.zero?

    if spot_hit_status.nil?
      Rollbar.error('spot_hit_rcs_data: statut RCS inconnu', status: change['status'], changes: change)
      return
    end

    error = change['error']
    Rollbar.error('spot_hit_rcs_data: erreur de livraison RCS', errors: error) if error.present?

    message = find_rcs_event(change)
    return if message.nil?

    attributes = { spot_hit_status: spot_hit_status }
    attributes[:is_fallback] = true if change['channelId'] == 'fallback'
    message.update!(attributes)
  end

  def find_rcs_event(change)
    campaign_id = change.dig('context', 'campaign_id')
    unless campaign_id
      Rollbar.error('spot_hit_rcs_data: event non trouvé', changes: change)
      return
    end

    phone = Phonelib.parse(change['userId'].to_s.strip).e164
    parent = Parent.find_by(phone_number: phone)
    unless parent
      Rollbar.error('spot_hit_rcs_data: parent non found', changes: change)
      return
    end

    Events::TextMessage.find_by(spot_hit_rcs_id: campaign_id, related_type: 'Parent', related_id: parent.id)
  end
end
