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
    Event.where(spot_hit_message_id: params[:id_message]).update_all(spot_hit_status: params[:statut])
    head :ok
  end

  def spot_hit_response
    parsed_phone = Phonelib.parse(params[:numero])
    event = Event.new({
      related: Parent.find_by(phone_number: parsed_phone.e164),
      body: params[:message],
      spot_hit_message_id: params[:id],
      spot_hit_status: 1,
      type: 'Events::TextMessage',
      occurred_at: Time.at(params[:date].to_i),
      originated_by_app: false
    })
    if event.save
      head :ok
    else
      head :unprocessable_entity
    end
  end
end
