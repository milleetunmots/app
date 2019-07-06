class CreateTasks < ActiveRecord::Migration[6.0]
  def change
    create_table :tasks do |t|
      t.belongs_to :reporter, foreign_key: { to_table: :admin_users }
      t.belongs_to :assignee, foreign_key: { to_table: :admin_users }
      t.belongs_to :related, polymorphic: true

      t.string :title, null: false
      t.text :description
      t.date :due_date

      t.date :done_at

      t.timestamps null: false
    end
  end
end
