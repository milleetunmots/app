class AddSupportStopInformationsToChildSupports < ActiveRecord::Migration[6.1]
  def change
    add_reference :child_supports, :support_stop_caller, foreign_key: { to_table: :admin_users }, null: true
    add_column :child_supports, :support_stop_date, :datetime, null: true
  end
end
