class Events::TextMessageDecorator < EventDecorator

  def name
    [
      related_name,
      occurred_at
    ].join(' - ')
  end

  def timeline_description
    if originated_by_app
      'Envoyé par <span style="color: #e84e0f;">1001mots</span>.'.html_safe
    else
      [
        related_link,
        'a répondu par SMS'
      ].join(' ').html_safe
    end
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
