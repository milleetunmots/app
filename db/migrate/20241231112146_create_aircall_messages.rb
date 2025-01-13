class CreateAircallMessages < ActiveRecord::Migration[6.1]
  def change
    create_table :aircall_messages do |t|
      t.string :aircall_id, index: true
      t.string :direction
      t.belongs_to :child_support
      t.belongs_to :parent
      t.references :caller, foreign_key: { to_table: :admin_users }, null: false
      t.datetime :sent_at
      t.text :body
      t.string :status
      t.timestamps
    end
  end
end
