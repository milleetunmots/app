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
    column :is_programmed
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
      row :is_programmed
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
      f.input :support_module,
              collection: resource.support_module_collection,
              input_html: {data: {select2: {}}}
    end
    f.actions
  end

  permit_params :child_id, :parent_id, :support_module_id, :is_completed

  scope :all, default: true

  scope :with_support_module, group: :support_module_choice
  scope :with_the_choice_to_make_by_us, group: :support_module_choice
  scope :without_choice, group: :support_module_choice

  scope :programmed, group: :programming
  scope :not_programmed, group: :programming

  filter :is_completed, as: :boolean
  filter :is_programmed, as: :boolean
  filter :support_module_name, as: :string
  filter :child_last_name, as: :string
  filter :child_first_name, as: :string
  filter :parent_last_name, as: :string
  filter :parent_first_name, as: :string
  filter :created_at
  filter :choice_date, as: :date_range

  action_item :program, only: :index do
    link_to "Programmer les modules", [:program, :admin, :children_support_modules], method: :post
  end

  collection_action :program, method: :post do
    service = ChildSupport::ProgramChosenModulesService.new.call

    if service.errors.empty?
      redirect_to admin_children_support_modules_path, notice: "modules programmés avec succès"
    else
      flash[:error] = service.errors

      redirect_to admin_children_support_modules_path
    end
  end

end
