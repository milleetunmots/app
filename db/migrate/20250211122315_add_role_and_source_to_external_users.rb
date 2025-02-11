class AddRoleAndSourceToExternalUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :external_users, :role, :string, null: false, default: 'pmi_user'
    add_reference :external_users, :source, foreign_key: true
  end
end
