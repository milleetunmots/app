class Events::TextMessageDecorator < EventDecorator

  def name
    [
      related_name,
      occurred_at
    ].join(' - ')
  end

  def timeline_description
    [
      related_link,
      'a répondu par SMS'
    ].join(' ').html_safe
  end

  def truncated_body
    model.body.truncate 30,
                        separator: /\s/,
                        omission: ' (…)'
  end

end
