class AddCanSendAutomaticSmsToAdminUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :admin_users, :can_send_automatic_sms, :boolean, null: false, default: true
  end
end
