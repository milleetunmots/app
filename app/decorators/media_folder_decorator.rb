class MediaFolderDecorator < BaseDecorator

  def admin_link(options = {})
    with_icon = options.delete(:with_icon)

    txt = options.delete(:label) || name
    if with_icon
      txt = h.content_tag(:i, '', class: "fas fa-folder") + "&nbsp;".html_safe + txt
    end
    h.link_to txt, [:admin, model], options
  end

  def breadcrumb
    if model.parent.nil?
      [
        h.link_to('Médiathèque', [:admin, :media_folders])
      ]
    else
      model.parent.decorate.breadcrumb + [
        h.link_to(model.parent.name, [:admin, model.parent])
      ]
    end
  end

end
