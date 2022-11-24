ActiveAdmin.register ChildrenSupportModule do

  config.clear_action_items!

  decorate_with ChildrenSupportModuleDecorator

  index do
    column :name
    column :parent_name
    column :child_name
    column :created_at
    column :choice_date
  end

  filter :support_module_name, as: :string
  filter :child_last_name, as: :string
  filter :child_first_name, as: :string
  filter :parent_last_name, as: :string
  filter :parent_first_name, as: :string
  filter :created_at
  filter :choice_date, as: :date_range


  controller do
    def scoped_collection
      end_of_association_chain.where(is_completed: true)
    end
  end
end
