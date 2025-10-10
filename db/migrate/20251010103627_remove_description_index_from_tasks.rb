class RemoveDescriptionIndexFromTasks < ActiveRecord::Migration[6.1]
  def change
    remove_index :tasks, :description
  end
end
