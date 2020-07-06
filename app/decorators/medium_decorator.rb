class MediumDecorator < BaseDecorator

  def type_name
    model.type.constantize.model_name.human
  end

end
