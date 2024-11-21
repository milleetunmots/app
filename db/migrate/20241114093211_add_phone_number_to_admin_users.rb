class AddPhoneNumberToAdminUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :admin_users, :aircall_phone_number, :string
  end
end
