class SupportModuleDecorator < BaseDecorator

  def ages
    SupportModule.human_attribute_name("ages.#{model.ages}")
  end

end
