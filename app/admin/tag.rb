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
    column :is_visible_by_callers_and_animators
    actions
  end

  filter :name
  filter :is_visible_by_callers_and_animators
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
      f.input :is_visible_by_callers_and_animators
    end
    f.actions
  end

  permit_params :name, :color, :is_visible_by_callers_and_animators

  # ---------------------------------------------------------------------------
  # SHOW
  # ---------------------------------------------------------------------------

  show do
    attributes_table do
      row :name
      row :color do |decorated|
        decorated.colored_color
      end
      row :is_visible_by_callers_and_animators
      row :created_at
      row :updated_at
    end
  end

end
