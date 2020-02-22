ActiveAdmin.register Parent do

  decorate_with ParentDecorator

  has_paper_trail
  has_tasks

  # ---------------------------------------------------------------------------
  # INDEX
  # ---------------------------------------------------------------------------

  index do
    selectable_column
    id_column
    column :gender do |model|
      model.gender_status
    end
    column :first_name
    column :last_name
    column :children
    column :phone_number
    column :email
    column :is_ambassador
    column :redirection_unique_visits
    column :created_at do |model|
      l model.created_at.to_date, format: :default
    end
    column :updated_at do |model|
      l model.updated_at.to_date, format: :default
    end
    actions
  end

  filter :gender,
         as: :check_boxes,
         collection: proc { parent_gender_select_collection }
  filter :first_name
  filter :last_name
  filter :phone_number
  filter :is_lycamobile
  filter :email
  filter :letterbox_name
  filter :address
  filter :postal_code
  filter :city_name
  filter :is_ambassador
  filter :terms_accepted_at
  filter :created_at
  filter :updated_at

  # ---------------------------------------------------------------------------
  # FORM
  # ---------------------------------------------------------------------------

  form do |f|
    f.inputs do
      f.input :gender,
              as: :radio,
              collection: parent_gender_select_collection
      f.input :first_name
      f.input :last_name
      f.input :phone_number,
              input_html: { value: f.object.decorate.phone_number }
      f.input :is_lycamobile
      f.input :email
      f.input :letterbox_name
      f.input :address
      f.input :postal_code
      f.input :city_name
      f.input :is_ambassador
      f.input :job
      f.input :terms_accepted_at, as: :datepicker
    end
    f.actions
  end

  permit_params :gender, :first_name, :last_name,
                :phone_number, :is_lycamobile, :email,
                :letterbox_name, :address, :postal_code, :city_name,
                :is_ambassador, :job, :terms_accepted_at

  # ---------------------------------------------------------------------------
  # SHOW
  # ---------------------------------------------------------------------------

  show do
    attributes_table do
      row :gender do |model|
        model.gender_status
      end
      row :first_name
      row :last_name
      row :phone_number
      row :is_lycamobile
      row :email
      row :letterbox_name
      row :address
      row :postal_code
      row :city_name
      row :created_at
      row :updated_at
      row :children
      row :is_ambassador
      row :job
      row :terms_accepted_at
      row :redirection_urls_count
      row :redirection_url_visits_count
      row :redirection_url_unique_visits_count
      row :redirection_unique_visit_rate
      row :redirection_visit_rate
    end
  end

end
