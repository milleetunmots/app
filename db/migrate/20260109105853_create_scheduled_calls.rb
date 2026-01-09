class CreateScheduledCalls < ActiveRecord::Migration[7.0]
  def change
    create_table :scheduled_calls do |t|
      t.string :calendly_event_uri, null: false
      t.string :calendly_invitee_uri
      t.references :admin_user, foreign_key: true
      t.references :child_support, foreign_key: true
      t.references :parent, foreign_key: true
      t.integer :call_session
      t.datetime :scheduled_at
      t.integer :duration_minutes
      t.string :event_type_name
      t.string :event_type_uri
      t.string :invitee_email
      t.string :invitee_name
      t.text :invitee_comment
      t.string :status, default: 'scheduled', null: false
      t.datetime :canceled_at
      t.text :cancellation_reason
      t.jsonb :raw_payload, default: {}

      t.timestamps
    end

    add_index :scheduled_calls, :calendly_event_uri, unique: true
    add_index :scheduled_calls, :status
    add_index :scheduled_calls, :scheduled_at
  end
end
