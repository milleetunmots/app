ActiveAdmin.register Child do

  decorate_with ChildDecorator

  index do
    selectable_column
    id_column
    column :gender
    column :first_name
    column :last_name
    column :age, sortable: :birthdate
    column :parent1, sortable: :parent1_id
    column :parent2, sortable: :parent2_id
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
         collection: Hash[Child::GENDERS.map{|v| [Child.human_attribute_name("gender.#{v}"),v]}]
  filter :first_name
  filter :last_name
  filter :birthdate
  filter :created_at
  filter :updated_at

  form do |f|
    f.inputs do
      f.input :parent1, collection: Parent.all.map(&:decorate), input_html: { data: { select2: {} } }
      f.input :should_contact_parent1
      f.input :parent2, collection: Parent.all.map(&:decorate), input_html: { data: { select2: {} } }
      f.input :should_contact_parent2
      f.input :gender,
              as: :radio,
              collection: Hash[Child::GENDERS.map{|v| [Child.human_attribute_name("gender.#{v}"),v]}]
      f.input :first_name
      f.input :last_name
      f.input :birthdate, as: :datepicker
    end
    f.actions
  end
  permit_params :parent1_id, :parent2_id,
                :should_contact_parent1, :should_contact_parent2,
                :gender, :first_name, :last_name, :birthdate

  show do
    attributes_table do
      row :parent1
      row :should_contact_parent1
      row :parent2
      row :should_contact_parent2
      row :first_name
      row :last_name
      row :birthdate
      row :age
      row :gender
      row :created_at
      row :updated_at
    end
  end

end
