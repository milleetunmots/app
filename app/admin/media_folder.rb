ActiveAdmin.register MediaFolder do

  menu label: 'Dossiers', parent: 'Médiathèque'

  # actions :index

  decorate_with MediaFolderDecorator

  breadcrumb do
    if params[:id].nil?
      ['Médiathèque']
    else
      # weird issue: resource sometimes isn't already decorated
      resource.decorate.breadcrumb
    end
  end

  # ---------------------------------------------------------------------------
  # INDEX
  # ---------------------------------------------------------------------------

  index do
    render 'root'
  end

  # ---------------------------------------------------------------------------
  # FORM
  # ---------------------------------------------------------------------------

  form do |f|
    f.inputs do
      f.input :parent
      f.input :name
    end
    f.actions
  end

  permit_params :parent_id, :name

  # ---------------------------------------------------------------------------
  # SHOW
  # ---------------------------------------------------------------------------

  show do
    div do
      render 'show'
    end
  end

end
