class AddUnassignedNumberReactivationFields < ActiveRecord::Migration[7.0]
  def change
    add_column :child_supports, :support_stopped_for_unassigned_number_at, :datetime
    add_column :children, :contact_parent1_unset_for_unassigned_number, :boolean, default: false, null: false
    add_column :children, :contact_parent2_unset_for_unassigned_number, :boolean, default: false, null: false
  end
end
