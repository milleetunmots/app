class AddIsSupportModuleMessageToEvents < ActiveRecord::Migration[6.1]
  def change
    add_column :events, :is_support_module_message, :boolean, default: false, null: false
  end
end
