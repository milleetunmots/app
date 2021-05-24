class Media::ImageDecorator < MediumDecorator

  def file_link_tag(options = {})
    return nil unless model.file.attached?
    image_link_tag model.file, options
  end

  def file_tag(options = {})
    return nil unless model.file.attached?
    h.image_tag_with_max_size model.file, options
  end

  def buzz_expert_file_link_tag(options = {})
    return nil unless model.file.attached?
    variant = model.file_max_byte_size_variant(Media::Image::BUZZ_EXPERT_MAX_WEIGHT)
    return 'En construction' if variant.nil?
    image_link_tag variant, options
  end

  def icon_class
    :image
  end

  def preview
    h.content_tag :div,
                  '',
                  class: 'image',
                  style: "background-image: url('#{url_for(model.file)}')"
  end
end
