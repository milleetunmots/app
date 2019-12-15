class RedirectionTargetDecorator < BaseDecorator

  def redirection_urls_path
    admin_redirection_urls_path(q: {redirection_target_id_in: [model.id]})
  end

  def redirection_urls_link
    h.link_to redirection_urls_count, redirection_urls_path
  end

  def target_link
    txt = model.target_url + '&nbsp;' + h.content_tag(:i, '', class: 'fas fa-external-link-alt')
    h.link_to txt.html_safe, model.target_url, target: '_blank'
  end

  def redirection_urls_count
    model.redirection_urls_count || 0
  end

  def redirection_url_unique_visits_count
    return nil if redirection_urls_count.zero?
    model.redirection_url_unique_visits_count || 0
  end

  def unique_visit_rate
    return nil if redirection_urls_count.zero?
    h.number_to_percentage(model.unique_visit_rate * 100, precision: 0)
  end

  def redirection_url_visits_count
    return nil if redirection_urls_count.zero?
    model.redirection_url_visits_count || 0
  end

  def visit_rate
    return nil if redirection_urls_count.zero?
    h.number_to_percentage(model.visit_rate * 100, precision: 0)
  end

end
