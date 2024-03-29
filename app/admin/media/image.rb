ActiveAdmin.register Media::Image do

  menu parent: 'Médiathèque', label: 'Images', priority: 5

  decorate_with Media::ImageDecorator

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
    # column :theme
    column :tags do |model|
      model.tags(context: 'tags')
    end
    column :spot_hit_id
    column :file do |decorated|
      decorated.file_link_tag(max_height: '50px')
    end
    column :created_at do |decorated|
      decorated.created_at_date
    end
    column :updated_at do |decorated|
      decorated.updated_at_date
    end
    actions dropdown: true do |decorated|
      discard_links_args(decorated.model).each do |args|
        item *args
      end
    end
  end

  filter :name
  # filter :theme,
  #        as: :select,
  #        collection: proc { medium_theme_suggestions },
  #        input_html: { multiple: true, data: { select2: {} } }

  filter :occurred_at
  filter :created_at

  # ---------------------------------------------------------------------------
  # SHOW
  # ---------------------------------------------------------------------------

  show do
    attributes_table do
      row :folder
      row :name
      # row :theme
      row :tags
      row :spot_hit_id
      row :file do |decorated|
        decorated.file_link_tag(max_height: '500px')
      end
      # row :buzz_expert_file do |decorated|
      #   decorated.buzz_expert_file_link_tag
      # end
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
              include_blank: 'Aucun (dossier racine)',
              input_html: { data: { select2: {} } }
      f.input :name
      # f.input :theme,
      #         as: :datalist,
      #         collection: medium_theme_suggestions
      tags_input(f)
      f.input :file,
              label: "Image module",
              as: :file,
              hint: f.object.id && "Laissez ce champ vide pour ne pas modifier l'image"
    end
    f.actions
  end

  permit_params :folder_id, :name, :theme, :file, tags_params

end
