class AddCurrentSupportModuleToGroup < ActiveRecord::Migration[6.0]
  def change
    add_column :groups, :support_module_programmed, :integer, default: 0
  end
end
