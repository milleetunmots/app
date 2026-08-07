class AddForceSendToBlockedSendAttempts < ActiveRecord::Migration[7.0]

  def change
    add_column :blocked_send_attempts, :force_send, :boolean, default: false, null: false
  end
end
