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

  def family_redirection_urls_count
    model.family_redirection_urls_count || 0
  end

  def family_redirection_url_unique_visits_count
    return nil if family_redirection_urls_count.zero?
    model.family_redirection_url_unique_visits_count || 0
  end

  def family_unique_visit_rate
    return nil if family_redirection_urls_count.zero?
    h.number_to_percentage(model.family_unique_visit_rate * 100, precision: 0)
  end

  def family_redirection_url_visits_count
    return nil if family_redirection_urls_count.zero?
    model.family_redirection_url_visits_count || 0
  end

  def family_visit_rate
    return nil if family_redirection_urls_count.zero?
    h.number_to_percentage(model.family_visit_rate * 100, precision: 0)
  end

end
