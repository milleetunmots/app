class AddUnassignedNumberReactivatedAtToChildSupports < ActiveRecord::Migration[7.0]
  def change
    add_column :child_supports, :unassigned_number_reactivated_at, :datetime
  end
end
