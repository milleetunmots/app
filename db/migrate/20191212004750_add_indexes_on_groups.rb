class AddIndexesOnGroups < ActiveRecord::Migration[6.0]
  def change
    add_index :children_groups, :quit_at
    add_index :groups, :started_at
    add_index :groups, :ended_at
  end
end
