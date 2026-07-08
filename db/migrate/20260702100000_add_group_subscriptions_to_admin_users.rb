class AddGroupSubscriptionsToAdminUsers < ActiveRecord::Migration[7.0]

  def change
    add_column :admin_users, :group_subscriptions, :jsonb, default: {}, null: false
  end
end
