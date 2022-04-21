ActiveAdmin.register Family do

  config.clear_action_items!

  decorate_with FamilyDecorator

  has_tags

  # ---------------------------------------------------------------------------
  # INDEX
  # ---------------------------------------------------------------------------

  index do
    selectable_column
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

  csv do
    column :id

    column :parent1_name
    column :parent2_name
    column :all_children

    column :full_address

    column :tag_list

    column :created_at
    column :updated_at
  end

  permit_params tags_list: []
end
