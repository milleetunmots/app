class RedirectionUrlDecorator < BaseDecorator

  def owner
    model&.owner&.decorate&.admin_link
  end

  def owner_age
    model&.owner&.decorate&.age
  end

  def owner_gender_text
    model&.owner&.decorate&.gender_text
  end

  def owner_phone_number_national
    model&.owner&.decorate&.phone_number_national
  end

  def owner_registration_source
    model&.owner&.decorate&.registration_source
  end

  def visit_url
    h.visit_redirection_url(id: model.id, security_code: model.security_code)
  end

  def visit_link
    txt = visit_url + '&nbsp;' + h.content_tag(:i, '', class: 'fas fa-external-link-alt')
    h.link_to txt.html_safe, visit_url, target: '_blank'
  end

end
