class AddIsCompletedToChildrenSupportModule < ActiveRecord::Migration[6.0]
  def change
    add_column :children_support_modules, :is_completed, :boolean, default: false
  end
end
