class EventsController < ApplicationController

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
    Event.find_by(spot_hit_message_id: params[:id_message]).update(spot_hit_status: params[:statut])
    head :ok
  end

  def get_response
    response_parent = Event.new({
      related_id: Event.where(message_id: params[:source]).first.id,
      related_type: 'Event',
      body: params[:message],
      message_id: params[:id],
      status: 1,
      type: 'Events::TextMessage',
      occurred_at: Time.at(params[:date].to_i)
    })
    if response_parent.save
      head :ok
    else
      head :unprocessable_entity
    end
  end
end
