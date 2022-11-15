class AddAvailableSupportModulesToParents < ActiveRecord::Migration[6.0]
  def change
    add_column :parents, :available_support_module, :string, array: true

    add_index :parents, :available_support_module, using: 'gin'
  end
end
