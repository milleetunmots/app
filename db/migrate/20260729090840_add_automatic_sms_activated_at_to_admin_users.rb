class AddAutomaticSmsActivatedAtToAdminUsers < ActiveRecord::Migration[7.0]

  def change
    add_column :admin_users, :automatic_sms_activated_at, :datetime
  end
end
