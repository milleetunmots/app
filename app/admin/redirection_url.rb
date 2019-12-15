ActiveAdmin.register RedirectionUrl do
  menu parent: 'Redirection'

  actions :all, except: [:edit, :update]

  decorate_with RedirectionUrlDecorator

  # ---------------------------------------------------------------------------
  # INDEX
  # ---------------------------------------------------------------------------

  index do
    selectable_column
    id_column
    column :redirection_target, sortable: :redirection_target_id
    column :owner, sortable: :owner_id
    column :visit_url do |model|
      model.visit_link
    end
    column :redirection_url_visits_count
    column :created_at do |model|
      l model.created_at.to_date, format: :default
    end
    actions
  end

  filter :redirection_target,
         input_html: { multiple: true, data: { select2: {} } }
  filter :redirection_url_visits_count
  filter :created_at
  filter :updated_at

  # ---------------------------------------------------------------------------
  # SHOW
  # ---------------------------------------------------------------------------

  show do
    attributes_table do
      row :redirection_target
      row :owner
      row :security_code
      row :visit_url do |model|
        model.visit_link
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

    column :redirection_target_name
    column :redirection_target_target_url

    column :owner_first_name
    column :owner_last_name
    column :owner_birthdate
    column :owner_age
    column(:owner_gender) { |redirection_url| redirection_url.owner_gender_text }
    column :owner_letterbox_name
    column :owner_address
    column :owner_city_name
    column :owner_postal_code
    column :owner_phone_number_national
    column :owner_registration_source
    column :owner_registration_source_details
    column :owner_group_name
    column :owner_has_quit_group

    column :security_code
    column :visit_url
    column :redirection_url_visits_count

    column :created_at
    column :updated_at
  end

end
