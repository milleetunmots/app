class Events::TextMessageDecorator < EventDecorator

  def timeline_description
    [
      related_link,
      'a répondu par SMS'
    ].join(' ').html_safe
  end

end
