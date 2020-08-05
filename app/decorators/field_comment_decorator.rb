class FieldCommentDecorator < BaseDecorator

  def related_link
    model.related.decorate.admin_link
  end

  def icon_class
    :comment
  end

  def field
    model.related.class.human_attribute_name model.field
  end

end
