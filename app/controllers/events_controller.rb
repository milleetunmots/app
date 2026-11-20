class EventsController < ApplicationController
  skip_before_action :authenticate_admin_user!
  skip_before_action :verify_authenticity_token

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
    service = Parent::HandleStopService.new(
      phone_number: Phonelib.parse(params[:numero]).e164,
      occurred_at: params[:date].present? ? Time.zone.at(params[:date].to_i) : Time.zone.now,
      spot_hit_message_id: params[:id]
    ).call

    head(service.errors.empty? ? :ok : :unprocessable_entity)
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
        Rollbar.error('Events::SendMessageToParentResponseService', errors: response_service.errors)
      end
      head :ok
    else
      head :unprocessable_entity
    end
  end

  def spot_hit_rcs_data
    # Sous fort volume de webhooks RCS, on ne fait que valider/parser le payload
    # ici puis on délègue tout le traitement (lookups + écritures DB) à Sidekiq,
    # afin de libérer immédiatement le worker web.
    payload = JSON.parse(request.raw_post)
    Events::TextMessage::ProcessRcsDataJob.perform_later(payload)
    head :ok
  rescue JSON::ParserError => e
    Rollbar.error('spot_hit_rcs_data: invalid payload JSON', message: e.message, request: request)
    head :bad_request
  end
end
