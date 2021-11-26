class EventDecorator < BaseDecorator

  def related_link
    if related = model.related&.decorate
      if related.respond_to?(:admin_link)
        related.admin_link
      else
        auto_link related
      end
    else
      nil
    end
  end

  def related_first_child_group
    decorated_related_first_child&.group
  end

  def related_first_child_group_status
    decorated_related_first_child&.group_status
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

  def css_class_name
    model.type.split('::').last.underscore.gsub('_', '-')
  end

  def occurred_at
    h.l model.occurred_at, format: :message
  end

  def timeline_occurred_at
    h.l model.occurred_at.to_date, format: :message
  end

  private

  def decorated_related
    @decorated_related ||= model.related&.decorate
  end

  def decorated_related_first_child
    @decorated_related_first_child ||= model.related_first_child&.decorate
  end

end
