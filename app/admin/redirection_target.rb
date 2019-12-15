ActiveAdmin.register RedirectionTarget do
  menu parent: 'Redirection'

  decorate_with RedirectionTargetDecorator

  has_paper_trail
  has_tasks

  # ---------------------------------------------------------------------------
  # INDEX
  # ---------------------------------------------------------------------------

  index do
    selectable_column
    id_column
    column :name
    column :target_url
    column :redirection_urls_count
    column :redirection_url_unique_visits_count
    column :unique_visit_rate
    column :redirection_url_visits_count
    column :visit_rate
    column :created_at do |model|
      l model.created_at.to_date, format: :default
    end
    actions
  end

  filter :name
  filter :target_url
  filter :created_at
  filter :updated_at

  # ---------------------------------------------------------------------------
  # FORM
  # ---------------------------------------------------------------------------

  form do |f|
    f.inputs do
      f.input :name
      f.input :target_url
    end
    f.actions
  end

  permit_params :name, :target_url

  # ---------------------------------------------------------------------------
  # SHOW
  # ---------------------------------------------------------------------------

  show do
    attributes_table do
      row :name
      row :target_url
      row :redirection_urls_count
      row :redirection_url_visits_count
      row :redirection_url_unique_visits_count
      row :unique_visit_rate
      row :visit_rate
      row :created_at
      row :updated_at
    end
  end

end
