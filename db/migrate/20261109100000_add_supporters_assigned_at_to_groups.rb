class AddSupportersAssignedAtToGroups < ActiveRecord::Migration[7.0]
  def change
    add_column :groups, :supporters_assigned_at, :datetime
  end
end
