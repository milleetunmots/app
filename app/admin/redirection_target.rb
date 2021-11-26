ActiveAdmin.register RedirectionTarget do

  menu parent: 'Redirection'

  decorate_with RedirectionTargetDecorator

  has_better_csv
  use_discard

  # ---------------------------------------------------------------------------
  # INDEX
  # ---------------------------------------------------------------------------

  index do
    selectable_column
    id_column
    column :medium_name
    column :medium_url do |model|
      model.medium_link
    end
    column :redirection_urls do |model|
      model.redirection_urls_link
    end
    column :family_redirection_urls_count
    column :family_redirection_url_unique_visits_count
    column :family_unique_visit_rate
    column :family_redirection_url_visits_count
    column :family_visit_rate
    column :created_at do |model|
      l model.created_at.to_date, format: :default
    end
    actions dropdown: true do |decorated|
      discard_links_args(decorated.model).each do |args|
        item *args
      end
    end
  end

  filter :medium,
    collection: proc { redirection_target_medium_select_collection },
    input_html: { multiple: true, data: { select2: {} } }
  filter :created_at
  filter :updated_at

  # ---------------------------------------------------------------------------
  # FORM
  # ---------------------------------------------------------------------------

  form do |f|
    f.semantic_errors *f.object.errors.keys
    f.inputs do
      f.input :medium,
        collection: redirection_target_medium_select_collection,
        input_html: { data: { select2: {} } }
    end
    f.actions
  end

  permit_params :medium_id

  # ---------------------------------------------------------------------------
  # SHOW
  # ---------------------------------------------------------------------------

  show do
    attributes_table do
      row :medium_name
      row :medium_url do |model|
        model.medium_link
      end
      row :redirection_urls do |model|
        model.redirection_urls_link
      end
      row :family_redirection_urls_count
      row :family_redirection_url_visits_count
      row :family_redirection_url_unique_visits_count
      row :family_unique_visit_rate
      row :family_visit_rate
      row :created_at
      row :updated_at
    end
  end

  action_item :export_stats,
    only: :show do
    link_to 'Stats par famille', [:export_stats, :admin, resource]
  end
  member_action :export_stats do
    service = ExportRedirectionTargetStatsService.new(redirection_target: resource).call
    if service.errors.any?
      puts "Error: #{service.errors}"
      flash[:error] = 'Une erreur est survenue'
      redirect_to request.referer
    else
      send_data service.csv, filename: "url-#{resource.id}-stats-#{Date.today}.csv"
    end
  end

end
