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
          "a été absent à l'atelier (absence prévue)"
        when "not_planned_absence"
          "a été absent à l'atelier (absence non prévue)"
        when "queue"
          "est sur la file d'attente de l'atelier"
        else
          "a accepté l'invitation à un atelier le #{acceptation_date}"
        end
      elsif parent_response == "Non"
        "a refusé l'invitation à un atelier le #{acceptation_date}"
      else
        "a été invité à un atelier"
      end

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

end
