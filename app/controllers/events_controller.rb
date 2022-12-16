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
    Event::UpdateTextMessageStatusService.new(message_id_from_spot_hit: params[:id_message], status: params[:statut]).call

    head :ok
  end

  def spot_hit_stop
    parsed_phone = Phonelib.parse(params[:numero])
    parent = Parent.find_by(phone_number: parsed_phone.e164)
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

    parent.children.where.not(group_id: nil).where(group_status: %w[active paused]).each do |child|
      child.parent1 == parent ? child.should_contact_parent1 = false : child.should_contact_parent2 = false
      if child.should_contact_parent1 == false && child.should_contact_parent2 == false
        child.group_status = "stopped"
        child.group_end = Time.now
      end
      child.save(validate: false)
    end

    head :ok
  end

  def spot_hit_response
    parsed_phone = Phonelib.parse(params[:numero])
    event = Events::TextMessage.new({
      related: Parent.find_by(phone_number: parsed_phone.e164),
      body: params[:message],
      spot_hit_message_id: params[:id],
      spot_hit_status: 1,
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
