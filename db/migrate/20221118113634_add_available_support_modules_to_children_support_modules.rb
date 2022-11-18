class AddAvailableSupportModulesToChildrenSupportModules < ActiveRecord::Migration[6.0]
  def change
    add_column :children_support_modules, :available_support_module_list, :string, array: true
  end
end
