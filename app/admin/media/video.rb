ActiveAdmin.register Media::Video do

  menu parent: 'Médiathèque', label: 'Vidéos', priority: 7

  decorate_with Media::VideoDecorator

  has_better_csv
  has_paper_trail
  has_tags
  use_discard

  # ---------------------------------------------------------------------------
  # INDEX
  # ---------------------------------------------------------------------------

  index download_links: false do
    selectable_column
    id_column
    column :name
    # column :theme
    column :tags do |model|
      model.tags(context: 'tags')
    end
    column :url do |decorated|
      decorated.url_link
    end
    column :created_at do |decorated|
      decorated.created_at_date
    end
    column :updated_at do |decorated|
      decorated.updated_at_date
    end
    column :airtable_id
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
  filter :url

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
      row :url do |decorated|
        decorated.url_link
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
        include_blank: 'Aucun (dossier racine)',
        input_html: {data: {select2: {}}}
      f.input :name
      # f.input :theme,
      #         as: :datalist,
      #         collection: medium_theme_suggestions
      tags_input(f)
      f.input :url
    end
    f.actions
  end

  action_item :new_videos, only: :index do
    link_to 'Importer depuis Airtable', %i[import_from_airtable admin media videos]
  end

  collection_action :import_from_airtable do
    service = Video::ImportFromAirtableService.new.call

    redirect_back(fallback_location: root_path, notice: "Nouvelles vidéos: #{service.new_videos.count}. Vidéos modifiées: #{service.updated_videos.count}")
  end

  permit_params :folder_id, :name, :theme, :url, tags_params
end
