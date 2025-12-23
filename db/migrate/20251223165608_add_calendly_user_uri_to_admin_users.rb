class AddCalendlyUserUriToAdminUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :admin_users, :calendly_user_uri, :string
  end
end
