class Events::TextMessageDecorator < EventDecorator

  def related_first_child_link
    model.related_first_child&.decorate&.admin_link
  end

  def related_name
    model.related&.decorate&.name
  end

  def related_first_child_name
    model.related_first_child&.decorate&.name
  end

end
