ActiveAdmin.register Family do

  decorate_with FamilyDecorator

  has_tags

  # ---------------------------------------------------------------------------
  # INDEX
  # ---------------------------------------------------------------------------

  index do
    selectable_column
    id_column
    column :parent1
    column :parent2
    column :children
    column :tags
    column :created_at do |model|
      l model.created_at.to_date, format: :default
    end
    column :updated_at do |model|
      l model.updated_at.to_date, format: :default
    end
  end
end
