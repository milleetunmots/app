class AddAircallNumberIdToAdminUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :admin_users, :aircall_number_id, :bigint
  end
end
