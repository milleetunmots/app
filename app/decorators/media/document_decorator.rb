class Media::DocumentDecorator < MediumDecorator

  def file_link_tag
    txt = model.name + '&nbsp;' + h.content_tag(:i, '', class: 'fas fa-external-link-alt')
    h.link_to txt.html_safe, model.file, target: '_blank'
  end

  def icon_class
    'file-alt'
  end

  def preview
    # nothing
  end

end
