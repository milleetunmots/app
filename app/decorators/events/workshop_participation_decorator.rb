class Events::WorkshopParticipationDecorator < EventDecorator

  def timeline_description
    [
      related_link,
      'a participé à un atelier.'
    ].join(' ').html_safe
  end

end
