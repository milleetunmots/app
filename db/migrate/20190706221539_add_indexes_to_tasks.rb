class AddIndexesToTasks < ActiveRecord::Migration[6.0]
  def change
    add_index :tasks, :title
    add_index :tasks, :description
    add_index :tasks, :due_date
    add_index :tasks, :done_at
  end
end
