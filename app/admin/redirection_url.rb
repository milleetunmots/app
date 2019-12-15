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
    column :visit_url
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
      row :visit_url
      row :redirection_url_visits_count
      row :created_at
      row :updated_at
    end
  end

end
