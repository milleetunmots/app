class RedirectionUrlDecorator < BaseDecorator

  def decorated_owner
    @decorated_owner ||= model&.owner&.decorate
  end

  def owner
    decorated_owner&.admin_link
  end

  def owner_age
    decorated_owner&.age
  end

  def owner_gender_text
    decorated_owner&.gender_text
  end

  def owner_phone_number_national
    decorated_owner&.phone_number_national
  end

  def owner_registration_source
    decorated_owner&.registration_source
  end

  def visit_url
    h.visit_redirection_url(id: model.id, security_code: model.security_code)
  end

  def visit_link
    txt = visit_url + '&nbsp;' + h.content_tag(:i, '', class: 'fas fa-external-link-alt')
    h.link_to txt.html_safe, visit_url, target: '_blank'
  end

end
