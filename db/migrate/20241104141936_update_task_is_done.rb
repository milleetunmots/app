class UpdateTaskIsDone < ActiveRecord::Migration[6.1]

  def change
    add_column :tasks, :status, :string
    Task.where.not(done_at: nil).update(status: 'done')
  end
end
