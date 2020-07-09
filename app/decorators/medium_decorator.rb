class MediumDecorator < BaseDecorator

  def type_name
    model.type.constantize.model_name.human
  end

  def css_class_name
    model.type.split('::').last.underscore.gsub('_', '-')
  end

end
