class AddCanExportDataToAdminUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :admin_users, :can_export_data, :boolean, null: false, default: false
  end
end
