class CreateBlockedSendAttempts < ActiveRecord::Migration[7.0]

  def change
    create_table :blocked_send_attempts do |t|
      t.string :provider, null: false
      t.string :kind, null: false
      t.string :detected_values, array: true, null: false, default: []
      t.text :message_body, null: false
      t.jsonb :replay_params, null: false, default: {}
      t.string :status, null: false, default: 'pending'
      t.datetime :resolved_at

      t.timestamps
    end

    add_index :blocked_send_attempts, :status
  end
end
