class AddGroupStatusToChildren < ActiveRecord::Migration[6.0]
  def change
    add_column :children, :group_status, :string, default: "waiting"
    add_column :children, :group_start, :date
    add_column :children, :group_end, :date
  end
end
