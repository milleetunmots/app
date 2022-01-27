class MediaFolderDecorator < BaseDecorator

  def icon_class
    :folder
  end

  def breadcrumb
    if model.parent.nil?
      [
        h.link_to("Médiathèque", [:admin, :media_folders])
      ]
    else
      model.parent.decorate.breadcrumb + [
        h.link_to(model.parent.name, [:admin, model.parent])
      ]
    end
  end
end
