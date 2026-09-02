class AddTwoFactorToAdminUsers < ActiveRecord::Migration[7.0]

  def change
    add_column :admin_users, :phone_number, :string
    add_column :admin_users, :two_factor_enabled, :boolean, default: false, null: false
    add_column :admin_users, :otp_code_digest, :string
    add_column :admin_users, :otp_sent_at, :datetime
    add_column :admin_users, :otp_attempts, :integer, default: 0, null: false
  end
end
