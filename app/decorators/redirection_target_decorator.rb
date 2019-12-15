class RedirectionTargetDecorator < BaseDecorator

  def target_url
    txt = model.target_url + '&nbsp;' + h.content_tag(:i, '', class: 'fas fa-external-link-alt')
    h.link_to txt.html_safe, model.target_url, target: '_blank'
  end

  def unique_visit_rate
    model.unique_visit_rate && h.number_to_percentage(model.unique_visit_rate * 100, precision: 0)
  end

  def visit_rate
    model.visit_rate && h.number_to_percentage(model.visit_rate * 100, precision: 0)
  end

end
