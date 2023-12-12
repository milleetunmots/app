class RedirectionUrlDecorator < BaseDecorator

  def redirection_target_link
    decorated_redirection_target&.admin_link
  end

  def parent_link
    decorated_parent&.admin_link
  end

  def parent_gender
    decorated_parent&.gender
  end

  def child_link
    decorated_child&.admin_link
  end

  def child_age
    decorated_child&.age
  end

  def child_gender
    decorated_child&.gender
  end

  def child_source
    decorated_child&.source
  end

  def visit_url
    h.visit_redirection_url(id: model.id, security_code: model.security_code)
  end

  def visit_link
    txt = visit_url + '&nbsp;' + h.content_tag(:i, '', class: 'fas fa-external-link-alt')
    h.link_to txt.html_safe, visit_url, target: '_blank'
  end

  def child_group_status
    decorated_child&.group_status
  end

  private

  def decorated_redirection_target
    @decorated_redirection_target ||= model.redirection_target&.decorate
  end

  def decorated_parent
    @decorated_parent ||= model.parent&.decorate
  end

  def decorated_child
    @decorated_child ||= model.child&.decorate
  end
end
