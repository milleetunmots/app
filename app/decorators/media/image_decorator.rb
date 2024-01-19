class Media::ImageDecorator < MediumDecorator

  def file_link_tag(options = {})
    return nil unless model.file.attached?
    options.merge!(source: model.file)
    image_link_tag(**options)
  end

  def file_tag(options = {})
    return nil unless model.file.attached?
    options.merge!(source: model.file)
    h.image_tag_with_max_size **options
  end

  def buzz_expert_file_link_tag(options = {})
    return nil unless model.file.attached?
    variant = model.file_max_byte_size_variant(Media::Image::BUZZ_EXPERT_MAX_WEIGHT)
    return 'En construction' if variant.nil?
    options.merge!(source: variant)
    image_link_tag(**options)
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
