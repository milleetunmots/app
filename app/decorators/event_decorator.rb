class EventDecorator < BaseDecorator

  def related_link
    related.decorate.admin_link
  end

  def css_class_name
    model.type.split('::').last.underscore.gsub('_', '-')
  end

  def occurred_at
    h.l model.occurred_at, format: :message
  end

end
