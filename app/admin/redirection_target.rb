ActiveAdmin.register RedirectionTarget do

  menu parent: 'Redirection'

  decorate_with RedirectionTargetDecorator

  # ---------------------------------------------------------------------------
  # INDEX
  # ---------------------------------------------------------------------------

  index do
    selectable_column
    id_column
    column :name
    column :target_url do |model|
      model.target_link
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
      row :target_url do |model|
        model.target_link
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

end
