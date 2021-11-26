class AddGroupStatusToChildren < ActiveRecord::Migration[6.0]
  def change
    add_column :children, :group_status, :string, default: "waiting"
    add_column :children, :group_start, :date
    add_column :children, :group_end, :date

    Child.where.not(group_id: nil).each do |child|
      group = Group.find(child.group_id)
      child.update group_start: group.started_at
      if group.ended_at.past?
        child.update group_end: group.ended_at, group_status: "stopped"
      else
        child.update group_status: child.has_quit_group ? "paused" : "active"
      end
    end

    remove_column :children, :has_quit_group
  end
end
