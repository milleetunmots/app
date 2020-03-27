ActiveAdmin.register Group do

  decorate_with GroupDecorator

  has_better_csv
  has_paper_trail
  has_tasks

  # ---------------------------------------------------------------------------
  # INDEX
  # ---------------------------------------------------------------------------

  index do
    selectable_column
    id_column
    column :name
    column :children
    column :started_at
    column :ended_at
    column :created_at do |model|
      l model.created_at.to_date, format: :default
    end
    column :updated_at do |model|
      l model.updated_at.to_date, format: :default
    end
    actions
  end

  filter :name
  filter :started_at
  filter :ended_at
  filter :created_at
  filter :updated_at

  scope :all, default: true
  scope :not_ended
  scope :ended

  # ---------------------------------------------------------------------------
  # FORM
  # ---------------------------------------------------------------------------

  form do |f|
    f.inputs do
      f.input :name
      f.input :started_at, as: :datepicker
      f.input :ended_at, as: :datepicker
    end
    f.actions
  end

  permit_params :name, :started_at, :ended_at

  # ---------------------------------------------------------------------------
  # SHOW
  # ---------------------------------------------------------------------------

  show do
    attributes_table do
      row :name
      row :children
      row :started_at
      row :ended_at
    end
  end

end
