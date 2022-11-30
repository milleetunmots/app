ActiveAdmin.register ChildrenSupportModule do

  decorate_with ChildrenSupportModuleDecorator

  includes :child, :parent, :support_module

  index do
    column :name
    column :is_completed
    column :parent_name
    column :child_name
    column :created_at
    column :choice_date
    actions
  end

  show do
    attributes_table do
      row :is_completed
      row :child_name
      row :parent_name
      row :name
      row :available_support_module_names
      row :created_at
      row :choice_date
    end
  end

  form do |f|
    f.semantic_errors *f.object.errors.keys
    f.inputs do
      f.input :is_completed
      f.input :child,
              collection: child_selection_collection,
              input_html: {data: {select2: {}}}
      f.input :parent,
              collection: child_parent_select_collection,
              input_html: {data: {select2: {}}}
      f.input :support_module, input_html: {data: {select2: {}}}
    end
    f.actions
  end

  permit_params :child_id, :parent_id, :support_module_id

  filter :is_completed, as: :boolean
  filter :support_module_name, as: :string
  filter :child_last_name, as: :string
  filter :child_first_name, as: :string
  filter :parent_last_name, as: :string
  filter :parent_first_name, as: :string
  filter :created_at
  filter :choice_date, as: :date_range

end
