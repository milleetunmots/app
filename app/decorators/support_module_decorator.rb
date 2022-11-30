class SupportModuleDecorator < BaseDecorator

  def ages
    SupportModule.human_attribute_name("ages.#{model.ages}")
  end

  def picture_tag(options = {})
    return nil unless model.picture.attached?
    h.image_tag_with_max_size model.picture, options
  end
end
