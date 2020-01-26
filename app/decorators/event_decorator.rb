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

  def css_class_name
    model.type.split('::').last.underscore.gsub('_', '-')
  end

  def occurred_at
    h.l model.occurred_at, format: :message
  end

end
