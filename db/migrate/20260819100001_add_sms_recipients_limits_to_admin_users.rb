class AddSmsRecipientsLimitsToAdminUsers < ActiveRecord::Migration[7.0]

  def change
    add_column :admin_users, :sms_hourly_recipients_limit, :integer, null: false, default: 50
    add_column :admin_users, :sms_daily_recipients_limit, :integer, null: false, default: 200
  end
end
