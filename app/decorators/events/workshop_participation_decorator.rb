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
      'a participé à un atelier'
    ].join(' ').html_safe
  end

  def truncated_comments
    model.comments.truncate 30,
      separator: /\s/,
      omission: ' (…)'
  end

end
