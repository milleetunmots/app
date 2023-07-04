class AddModuleIndexToChildrenSupportModule < ActiveRecord::Migration[6.0]
  def change
    add_column :children_support_modules, :module_index, :integer
  end
end
