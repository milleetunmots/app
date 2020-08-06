ActiveAdmin.register Media::Document do

  menu parent: 'Médiathèque', label: 'Documents'

  decorate_with Media::DocumentDecorator

  has_better_csv
  has_paper_trail
  has_tags
  use_discard

  # ---------------------------------------------------------------------------
  # INDEX
  # ---------------------------------------------------------------------------

  # doesn't work, sadly
  # includes :file

  index do
    selectable_column
    id_column
    column :name
    column :theme
    column :tags
    column :file do |decorated|
      decorated.file_tag
    end
    column :created_at do |decorated|
      decorated.created_at_date
    end
    column :updated_at do |decorated|
      decorated.updated_at_date
    end
    actions do |decorated|
      discard_links(decorated.model, class: 'member_link')
    end
  end

  filter :name
  filter :theme,
         as: :select,
         collection: proc { medium_theme_suggestions },
         input_html: { multiple: true, data: { select2: {} } }

  filter :occurred_at
  filter :created_at

  # ---------------------------------------------------------------------------
  # SHOW
  # ---------------------------------------------------------------------------

  show do
    attributes_table do
      row :folder
      row :name
      row :theme
      row :tags
      row :file do |decorated|
        decorated.file_tag
      end
      row :created_at
      row :discarded_at
    end
  end

  # ---------------------------------------------------------------------------
  # FORM
  # ---------------------------------------------------------------------------

  form do |f|
    f.semantic_errors
    f.inputs do
      f.input :folder,
              collection: medium_folder_select_collection,
              prompt: 'Aucun (dossier racine)',
              input_html: { data: { select2: {} } }
      f.input :name
      f.input :theme,
              as: :datalist,
              collection: medium_theme_suggestions
      tags_input(f)
      f.input :file, as: :file
    end
    f.actions
  end

  permit_params :folder_id, :name, :theme, :file, tags_params

end
