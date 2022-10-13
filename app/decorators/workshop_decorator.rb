class WorkshopDecorator < BaseDecorator

  def animator_csv
    animator.name
  end
  def workshop_address
    "#{address} #{postal_code} #{city_name}"
  end

  def workshop_participants
    arbre do
      ul do
        parents.decorate.each do |participant|
          li do
            participant.admin_link
          end
        end
      end
    end
  end

  def workshop_participants_csv
    parents.decorate.map(&:name).join("\n")
  end

  def parents_who_accepted
    arbre do
      ul do
        parents.decorate.each do |participant|
          response = Event.workshop_participations.find_by(
            workshop_id: model.id,
            related_id: participant.id).parent_response
          li do
            participant.admin_link if response == "Oui"
          end
        end
      end
    end
  end

  def parents_who_accepted_csv
    result = []
    parents.each do |parent|
      response = Event.workshop_participations.find_by(
        workshop_id: model.id,
        related_id: parent.id).parent_response
      result << parent.decorate.name if response == "Oui"
    end
    result.join("\n")
  end

  def parents_who_refused
    arbre do
      ul do
        parents.decorate.each do |participant|
          response = Event.workshop_participations.find_by(workshop_id: model.id, related_id: participant.id).parent_response
          li do
            participant.admin_link if response == "Non"
          end
        end
      end
    end
  end

  def parents_who_refused_csv
    result = []
    parents.each do |parent|
      response = Event.workshop_participations.find_by(
        workshop_id: model.id,
        related_id: parent.id).parent_response
      result << parent.decorate.name if response == "Non"
    end
    result.join("\n")
  end

  def parents_without_response
    arbre do
      ul do
        parents.decorate.each do |participant|
          response = Event.workshop_participations.find_by(workshop_id: model.id, related_id: participant.id).parent_response
          li do
            participant.admin_link unless response
          end
        end
      end
    end
  end

  def parents_without_response_csv
    result = []
    parents.each do |parent|
      response = Event.workshop_participations.find_by(
        workshop_id: model.id,
        related_id: parent.id).parent_response
      result << parent.decorate.name unless response
    end
    result.join("\n")
  end

  def topic
    Workshop.human_attribute_name("topic.#{model.topic}")
  end
end
