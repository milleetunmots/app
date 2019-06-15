ActiveAdmin.register Child do

  decorate_with ChildDecorator

  index do
    selectable_column
    id_column
    column :gender
    column :first_name
    column :last_name
    column :birthdate
    column :age
    column :parent1
    column :parent2
    column :created_at
    column :updated_at
    actions
  end

  filter :gender
  filter :first_name
  filter :last_name
  filter :birthdate
  filter :created_at

  form do |f|
    f.inputs do
      f.input :parent1, collection: Parent.all.map(&:decorate)
      f.input :parent2, collection: Parent.all.map(&:decorate)
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
                :gender, :first_name, :last_name, :birthdate

  show do
    attributes_table do
      row :parent1
      row :parent2
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
