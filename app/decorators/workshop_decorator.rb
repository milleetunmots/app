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
        events.where(parent_response: "Oui").each do |event|
          li do
            event.related.decorate.admin_link
          end
        end
      end
    end
  end

  def parents_who_accepted_csv
    events.where(parent_response: "Oui").map { |event| event.related.decorate.name }.join("\n")
  end

  def parents_who_refused
    arbre do
      ul do
        events.where(parent_response: "Non").each do |event|
          li do
            event.related.decorate.admin_link
          end
        end
      end
    end
  end

  def parents_who_refused_csv
    events.where(parent_response: "Non").map { |event| event.related.decorate.name }.join("\n")
  end

  def parents_without_response
    arbre do
      ul do
        events.where(parent_response: nil).each do |event|
          li do
            event.related.decorate.admin_link
          end
        end
      end
    end
  end

  def parents_without_response_csv
    events.where(parent_response: nil).map { |event| event.related.decorate.name }.join("\n")
  end

  def parent_invited_number
    events.count
  end

  def parent_who_accepted_number
    events.where(parent_response: "Oui").count
  end

  def parent_who_refused_number
    events.where(parent_response: "Non").count
  end

  def parent_who_ignored_number
    events.where(parent_response: nil).count
  end
end
