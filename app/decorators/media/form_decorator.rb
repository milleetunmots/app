class Media::FormDecorator < MediumDecorator

  def url_link
    txt = model.url + '&nbsp;' + h.content_tag(:i, '', class: 'fas fa-external-link-alt')
    h.link_to txt.html_safe, model.url, target: '_blank'
  end

  def icon_class
    :edit
  end

  def preview

  end

end
