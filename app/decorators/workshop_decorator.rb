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
        workshop_participations.only_accepted.each do |event|
          li do
            next unless event.related

            event.related.decorate.admin_link
          end
        end
      end
    end
  end

  def parents_who_accepted_csv
    workshop_participations.only_accepted.map { |event| event.related.decorate.name }.join("\n")
  end

  def parents_who_refused
    arbre do
      ul do
        workshop_participations.only_refused.each do |event|
          li do
            next unless event.related

            event.related.decorate.admin_link
          end
        end
      end
    end
  end

  def parents_who_refused_csv
    workshop_participations.only_refused.map { |event| event.related.decorate.name }.join("\n")
  end

  def parents_without_response
    arbre do
      ul do
        workshop_participations.where(parent_response: nil).each do |event|
          li do
            next unless event.related

            event.related.decorate.admin_link
          end
        end
      end
    end
  end

  def parents_without_response_csv
    workshop_participations.where(parent_response: nil).map { |event| event.related.decorate.name }.join("\n")
  end

  def parent_invited_number
    workshop_participations.count
  end

  def parent_who_accepted_number
    workshop_participations.only_accepted.count
  end

  def parent_who_refused_number
    workshop_participations.only_refused.count
  end

  def parent_who_ignored_number
    workshop_participations.where(parent_response: nil).count
  end

  def display_topic
    return if model.topic.blank?

    Workshop.human_attribute_name("topic.#{model.topic}")
  end
end
