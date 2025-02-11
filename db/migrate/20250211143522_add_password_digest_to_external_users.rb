class AddPasswordDigestToExternalUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :external_users, :password_digest, :string
  end
end
