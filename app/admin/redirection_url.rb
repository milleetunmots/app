ActiveAdmin.register RedirectionUrl do

  menu parent: 'Redirection'

  actions :all, except: [:new, :create, :edit, :update]

  decorate_with RedirectionUrlDecorator

  has_better_csv
  use_discard

  # ---------------------------------------------------------------------------
  # INDEX
  # ---------------------------------------------------------------------------

  index do
    selectable_column
    id_column
    column :redirection_target, sortable: :redirection_target_id do |decorated|
      decorated.redirection_target_link
    end
    column :parent, sortable: :parent_id do |decorated|
      decorated.parent_link
    end
    column :child, sortable: :child_id do |decorated|
      decorated.child_link
    end
    column :visit_url do |decorated|
      decorated.visit_link
    end
    column :redirection_url_visits_count
    column :created_at do |decorated|
      l decorated.created_at.to_date, format: :default
    end
    actions dropdown: true do |decorated|
      discard_links_args(decorated.model).each do |args|
        item *args
      end
    end
  end

  filter :redirection_target,
         input_html: { multiple: true, data: { select2: {} } }
  filter :redirection_url_visits_count
  filter :created_at
  filter :updated_at

  batch_action :generate_buzz_expert do |ids|
    @redirection_urls = batch_action_collection.where(id: ids)

    service = BuzzExpert::ExportRedirectionUrlsService.new(redirection_urls: @redirection_urls).call
    if service.errors.any?
      puts "Error: #{service.errors}"
      flash[:error] = "Une erreur est survenue: #{service.errors.join(', ')}"
      redirect_to request.referer
    else
      send_data service.csv, filename: "Buzz-Expert - #{csv_filename}"
    end
  end

  # ---------------------------------------------------------------------------
  # SHOW
  # ---------------------------------------------------------------------------

  show do
    attributes_table do
      row :redirection_target do |decorated|
        decorated.redirection_target_link
      end
      row :parent do |decorated|
        decorated.parent_link
      end
      row :child do |decorated|
        decorated.child_link
      end
      row :security_code
      row :visit_url do |decorated|
        decorated.visit_link
      end
      row :redirection_url_visits_count
      row :created_at
      row :updated_at
    end
  end

  # ---------------------------------------------------------------------------
  # CSV EXPORT
  # ---------------------------------------------------------------------------

  csv do
    column :id

    column :redirection_target_medium_name
    column :redirection_target_medium_url

    column :child_first_name
    column :child_last_name
    column :child_birthdate
    column :child_age
    column :child_gender
    column :child_children_source_name
    column :child_children_source_details
    column :child_group_name
    column :child_group_status

    column :parent_gender
    column :parent_first_name
    column :parent_last_name

    column :parent_letterbox_name
    column :parent_address
    column :parent_city_name
    column :parent_postal_code
    column :parent_phone_number_national

    column :security_code
    column :visit_url
    column :redirection_url_visits_count

    column :created_at
    column :updated_at
  end

end
