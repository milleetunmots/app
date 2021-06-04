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
    actions
  end

  filter :name
  filter :color
  filter :created_at
  filter :updated_at

  # ---------------------------------------------------------------------------
  # FORM
  # ---------------------------------------------------------------------------

  form do |f|
    div f.object.errors.inspect
    f.inputs do
      f.input :name
      f.input :color, as: :color
    end
    f.actions
  end

  permit_params :name, :color

  # ---------------------------------------------------------------------------
  # SHOW
  # ---------------------------------------------------------------------------

  show do
    attributes_table do
      row :name
      row :color do |decorated|
        decorated.colored_color
      end
      row :created_at
      row :updated_at
    end
  end

end
