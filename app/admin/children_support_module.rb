ActiveAdmin.register ChildrenSupportModule do

  decorate_with ChildrenSupportModuleDecorator

  includes :child, :parent, :support_module

  index do
    selectable_column
    id_column
    column :name_display
    column :is_completed
    column :parent_name
    column :child_name
    column :child_group_name
    column :available_support_module_names
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
      row :name_display
      row :available_support_module_names
      row :created_at
      row :choice_date
      row :is_programmed
    end
  end

  form do |f|
    f.semantic_errors *f.object.errors.keys
    if params[:action] == "new"
      f.object.is_completed = params[:is_completed] if params[:is_completed]
      f.object.parent_id = params[:parent_id] if params[:parent_id]
      f.object.child_id = params[:child_id] if params[:child_id]
      f.object.available_support_module_list = params[:available_support_module_list] if params[:available_support_module_list]
    end
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
      f.object.available_support_module_list.reject(&:blank?).each do |asm|
        f.input :available_support_module_list,
                multiple: true,
                value: asm
                # as: :hidden
      end

  end
    f.actions
  end

  permit_params :child_id, :parent_id, :support_module_id, :is_completed, available_support_module_list: []

  scope :all, default: true

  scope :with_support_module, group: :support_module_choice
  scope :with_the_choice_to_make_by_us, group: :support_module_choice
  scope :without_choice, group: :support_module_choice

  scope :programmed, group: :programming
  scope :not_programmed, group: :programming

  filter :is_completed, as: :boolean
  filter :is_programmed, as: :boolean
  filter :child_group_name, as: :string
  filter :support_module_name, as: :string
  filter :child_last_name, as: :string
  filter :child_first_name, as: :string
  filter :parent_last_name, as: :string
  filter :parent_first_name, as: :string
  filter :created_at
  filter :choice_date, as: :date_range

  batch_action :select_module, form: -> {
    {
      I18n.t("activerecord.models.children_support_module") => SupportModule.pluck(:name, :id)
    }
  } do |ids, inputs|
    batch_action_collection.where(id: ids, is_programmed: false).update_all(
      support_module_id: inputs[I18n.t("activerecord.models.children_support_module")].to_i
    )
    redirect_to request.referer, notice: "Modules choisis"
  end
end
