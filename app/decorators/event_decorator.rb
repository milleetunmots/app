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

  def related_current_child_group
    decorated_related_current_child&.group
  end

  def related_current_child_group_status
    decorated_related_current_child&.group_status
  end

  def related_current_child_link
    decorated_related_current_child&.admin_link
  end

  def related_current_child_name
    decorated_related_current_child&.name
  end

  def related_name
    decorated_related&.name
  end

  def css_class_name
    "#{model.type.split('::').last.underscore.gsub('_', '-')} #{model.originated_by_app ? 'sent_by_app_text_messages' : 'received_text_messages'}"
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

  def decorated_related_current_child
    @decorated_related_current_child ||= model.related_current_child&.decorate
  end

end
