class Events::WorkshopParticipationDecorator < EventDecorator

  def name
    [
      related_name,
      timeline_occurred_at
    ].join(' - ')
  end

  def timeline_description
    [
      related_link,
      if parent_response == "Oui"
        "a accepté l'invitation à un atelier le #{acceptation_date}"
        if parent_presence == "present"
          "a été présent à l'atelier"
        elsif parent_presence == "planned_absence"
          "a été absent à l'atelier (absence prévue)"
        elsif parent_presence == "not_planned_absence"
          "a été absent à l'atelier (absence non prévue)"
        else
          "est sur la file d'atente de l'atelier"
        end
      elsif parent_response == "Non"
        "a refusé l'invitation à un atelier le #{acceptation_date}"
      else
        'a été invité à un atelier'
      end
    ].join(' ').html_safe
  end

  def truncated_comments
    model.comments&.truncate 30,
      separator: /\s/,
      omission: ' (…)'
  end

end
