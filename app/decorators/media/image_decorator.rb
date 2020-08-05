class Media::ImageDecorator < MediumDecorator

  def file_link_tag(max_width: nil, max_height: nil)
    return nil unless model.file.attached?
    image_link_tag model.file, max_width: max_width, max_height: max_height
  end

  def file_tag(max_width: nil, max_height: nil)
    return nil unless model.file.attached?
    h.image_tag_with_max_size model.file, max_width: max_width, max_height: max_height
  end

  def buzz_expert_file_link_tag
    return nil unless model.file.attached?
    variant = model.file_max_byte_size_variant(Media::Image::BUZZ_EXPERT_MAX_WEIGHT)
    return 'En construction' if variant.nil?
    image_link_tag variant
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
