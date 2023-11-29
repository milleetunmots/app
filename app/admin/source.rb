ActiveAdmin.register Source do

  decorate_with SourceDecorator

  # ---------------------------------------------------------------------------
  # INDEX
  # ---------------------------------------------------------------------------

  index do
    selectable_column
    id_column
    column :name
    column :channel
    column :department
    column :utm
    column :comment
    actions
  end

  filter :name
  filter :channel
  filter :department
  filter :utm
  filter :created_at
  filter :updated_at

  # ---------------------------------------------------------------------------
  # FORM
  # ---------------------------------------------------------------------------

  form do |f|
    f.semantic_errors *f.object.errors.keys
    f.inputs do
      f.input :name
      f.input :channel, collection: Source::CHANNEL_LIST
      f.input :department
      f.input :utm
      f.input :comment
    end
    f.actions
  end

  permit_params :name, :channel, :department, :comment, :utm

  # ---------------------------------------------------------------------------
  # SHOW
  # ---------------------------------------------------------------------------

  show do
    attributes_table do
      row :name
      row :channel
      row :department
      row :utm
      row :comment
      row :created_at
      row :updated_at
    end
  end
end
