class AddRememberTokenToExternalUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :external_users, :remember_token, :string
  end
end
