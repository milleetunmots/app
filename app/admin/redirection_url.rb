ActiveAdmin.register RedirectionUrl do

  menu parent: 'Redirection'

  actions :all, except: [:edit, :update]

  decorate_with RedirectionUrlDecorator

  has_better_csv

  # ---------------------------------------------------------------------------
  # INDEX
  # ---------------------------------------------------------------------------

  index do
    selectable_column
    id_column
    column :redirection_target, sortable: :redirection_target_id
    column :parent, sortable: :parent_id do |model|
      model.parent_link
    end
    column :child, sortable: :child_id do |model|
      model.child_link
    end
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
      row :parent do |model|
        model.parent_link
      end
      row :child do |model|
        model.child_link
      end
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

    column :child_first_name
    column :child_last_name
    column :child_birthdate
    column :child_age
    column :child_gender
    column :child_registration_source
    column :child_registration_source_details
    column :child_group_name
    column :child_has_quit_group

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
