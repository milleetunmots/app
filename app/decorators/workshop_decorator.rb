class WorkshopDecorator < BaseDecorator
  def workshop_address
    "#{address} #{postal_code} #{city_name}"
  end

  def workshop_participants
    arbre do
      ul do
        participants.decorate.each do |participant|
          response = Event.workshop_participations.find_by(workshop_id: model.id, related_id: participant.id).parent_response
          li do
            participant.admin_link if response == "Oui"
          end
        end
      end
    end
  end

  def topic
    Workshop.human_attribute_name("topic.#{model.topic}")
  end
end
