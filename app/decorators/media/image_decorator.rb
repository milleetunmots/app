class Media::ImageDecorator < MediumDecorator

  def admin_link(options = {})
    with_icon = options.delete(:with_icon)

    txt = options.delete(:label) || name
    if with_icon
      txt = h.content_tag(:i, '', class: "fas fa-#{icon_class}") + "&nbsp;".html_safe + txt
    end
    options[:class] = [
      options[:class],
      model.discarded? ? 'discarded' : 'kept'
    ].compact.join(' ')
    h.link_to txt, [:admin, model], options
  end

  def file_tag(max_width: nil, max_height: nil)
    attached_image_tag model.file, max_width: max_width, max_height: max_height
  end

  def icon_class
    :image
  end

  def preview
    file_tag
  end

end
