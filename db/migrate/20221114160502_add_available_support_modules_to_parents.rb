class AddAvailableSupportModulesToParents < ActiveRecord::Migration[6.0]
  def change
    add_column :child_supports, :parent1_available_support_module_list, :string, array: true
    add_column :child_supports, :parent2_available_support_module_list, :string, array: true

    add_index :child_supports, :parent1_available_support_module_list, using: 'gin'
    add_index :child_supports, :parent2_available_support_module_list, using: 'gin'
  end
end
