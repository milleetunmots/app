class Events::WorkshopParticipationDecorator < EventDecorator

  def name
    [
      related_name,
      timeline_occurred_at
    ].join(' - ')
  end

  def timeline_description
    participation_state =
      if parent_response == "Oui"
        case parent_presence
        when "present"
          "a été présent à l'atelier"
        when "planned_absence"
          "a été absent à l'atelier (absence prévenue)"
        when "not_planned_absence"
          "a été absent à l'atelier (absence non prévenue)"
        when "queue"
          "est sur la liste d'attente pour cet atelier"
        else
          "a accepté l'invitation à un atelier le #{acceptation_date}"
        end
      elsif parent_response == "Non"
        "a refusé l'invitation à un atelier le #{acceptation_date}"
      else
        "a été invité à un atelier"
      end

    participation_state << ", mais celui-ci a été annulé" if workshop&.canceled

    [
      related_link,
      participation_state
    ].join(' ').html_safe
  end

  def truncated_comments
    model.comments&.truncate 30,
      separator: /\s/,
      omission: ' (…)'
  end

  def display_parent_presence
    return if model.parent_presence.blank?

    Event.human_attribute_name("parents_presence.#{model.parent_presence}")
  end

end
