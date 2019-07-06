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
    column :gender
    column :first_name
    column :last_name
    column :children
    column :phone_number
    column :email
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
         collection: Hash[Parent::GENDERS.map{|v| [Parent.human_attribute_name("gender.#{v}"),v]}]
  filter :first_name
  filter :last_name
  filter :phone_number
  filter :email
  filter :address
  filter :postal_code
  filter :city_name
  filter :created_at
  filter :updated_at

  # ---------------------------------------------------------------------------
  # FORM
  # ---------------------------------------------------------------------------

  form do |f|
    f.inputs do
      f.input :gender,
              as: :radio,
              collection: Hash[Parent::GENDERS.map{|v| [Parent.human_attribute_name("gender.#{v}"),v]}]
      f.input :first_name
      f.input :last_name
      f.input :phone_number,
              input_html: { value: f.object.decorate.phone_number }
      f.input :email
      f.input :address
      f.input :postal_code
      f.input :city_name
    end
    f.actions
  end

  permit_params :gender, :first_name, :last_name,
                :phone_number, :email, :address,
                :postal_code, :city_name

  # ---------------------------------------------------------------------------
  # SHOW
  # ---------------------------------------------------------------------------

  show do
    attributes_table do
      row :gender
      row :first_name
      row :last_name
      row :phone_number
      row :email
      row :address
      row :postal_code
      row :city_name
      row :created_at
      row :updated_at
      row :children
    end
  end

end
