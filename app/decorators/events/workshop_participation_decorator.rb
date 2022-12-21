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
      elsif parent_response == "Non"
        "a refusé l'invitation à un atelier"
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
