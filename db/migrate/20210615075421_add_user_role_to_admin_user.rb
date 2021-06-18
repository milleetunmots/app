class AddUserRoleToAdminUser < ActiveRecord::Migration[6.0]
  def change
    add_column :admin_users, :user_role, :string
  end
end
