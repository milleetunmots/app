class AddTreatedByToTasks < ActiveRecord::Migration[6.1]
  def change
    add_reference :tasks, :treated_by, foreign_key: { to_table: :admin_users }
  end
end
