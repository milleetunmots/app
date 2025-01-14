class CreateAircallCalls < ActiveRecord::Migration[6.1]
  def change
    create_table :aircall_calls do |t|
      t.bigint :aircall_id
      t.string :call_uuid, index: true
      t.string :direction
      t.boolean :answered
      t.belongs_to :child_support
      t.belongs_to :parent
      t.references :caller, foreign_key: { to_table: :admin_users }, null: false
      t.datetime :started_at
      t.datetime :answered_at
      t.datetime :ended_at
      t.integer :duration
      t.string :missed_call_reason
      t.string :asset_url
      t.integer :call_session
      t.text :notes, array: true, default: []
      t.text :tags, array: true, default: []
      t.timestamps
    end
  end
end
