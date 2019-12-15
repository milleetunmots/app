class RedirectionUrlDecorator < BaseDecorator

  def owner
    model&.owner&.decorate&.admin_link
  end

  def visit_url
    url = h.visit_redirection_url(id: model.id, security_code: model.security_code)
    txt = url + '&nbsp;' + h.content_tag(:i, '', class: 'fas fa-external-link-alt')
    h.link_to txt.html_safe, url, target: '_blank'
  end

end
