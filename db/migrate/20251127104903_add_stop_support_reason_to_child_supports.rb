class AddStopSupportReasonToChildSupports < ActiveRecord::Migration[6.1]
  def change
    add_column :child_supports, :stop_support_reason, :string
  end
end
