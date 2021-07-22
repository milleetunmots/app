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

  def spot_hit_status_value
    return unless spot_hit_status.present?

    Event::SPOT_HIT_STATUS[spot_hit_status]
  end

  def truncated_body
    # model.body.truncate 30,
    #                     separator: /\s/,
    #                     omission: ' (…)'
    model.body
  end

end
