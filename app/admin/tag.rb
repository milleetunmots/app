ActiveAdmin.register Tag, as: 'Tag' do

  decorate_with TagDecorator

  # ---------------------------------------------------------------------------
  # INDEX
  # ---------------------------------------------------------------------------

  index do
    selectable_column
    id_column
    column :name
    column :color do |decorated|
      decorated.colored_color
    end
    column :is_visible_by_callers
    actions
  end

  filter :name
  filter :color
  filter :is_visible_by_callers
  filter :created_at
  filter :updated_at

  # ---------------------------------------------------------------------------
  # FORM
  # ---------------------------------------------------------------------------

  form do |f|
    f.semantic_errors *f.object.errors.keys
    f.inputs do
      f.input :name
      f.input :color, as: :color
      f.input :is_visible_by_callers
    end
    f.actions
  end

  permit_params :name, :color, :is_visible_by_callers

  # ---------------------------------------------------------------------------
  # SHOW
  # ---------------------------------------------------------------------------

  show do
    attributes_table do
      row :name
      row :color do |decorated|
        decorated.colored_color
      end
      row :is_visible_by_callers
      row :created_at
      row :updated_at
    end
  end

end
