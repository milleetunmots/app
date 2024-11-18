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
        child.group_end = Time.zone.now
      end
      child.save(validate: false)
    end

    head :ok
  end

  def spot_hit_response
    parsed_phone = Phonelib.parse(params[:numero])
    response_service = Event::SendMessageToParentResponse.new(parsed_phone.e164).call
    if response_service.errors.any?
      p response_service.errors.join(' - ')
      Rollbar.error("Impossible to send message to parent with phone number #{parsed_phone} response : #{response_service.errors.join(' - ')}")
    end
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
      head :ok
    else
      head :unprocessable_entity
    end
  end
end
