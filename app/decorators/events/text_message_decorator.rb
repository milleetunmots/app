class Events::TextMessageDecorator < EventDecorator

  def related_first_child_group
    decorated_related_first_child&.group
  end

  def related_first_child_link
    decorated_related_first_child&.admin_link
  end

  def related_first_child_name
    decorated_related_first_child&.name
  end

  def related_name
    decorated_related&.name
  end

  private

  def decorated_related
    @decorated_related ||= model.related&.decorate
  end

  def decorated_related_first_child
    @decorated_related_first_child ||= model.related_first_child&.decorate
  end

end
