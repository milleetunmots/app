class Media::VideoDecorator < MediumDecorator

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

  def url_link
    txt = model.url + '&nbsp;' + h.content_tag(:i, '', class: 'fas fa-external-link-alt')
    h.link_to txt.html_safe, model.url, target: '_blank'
  end

end
