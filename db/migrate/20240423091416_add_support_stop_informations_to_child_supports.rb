class AddSupportStopInformationsToChildSupports < ActiveRecord::Migration[6.1]
  def change
    add_reference :child_supports, :stop_support_caller, foreign_key: { to_table: :admin_users }, null: true
    add_column :child_supports, :stop_support_details, :text, null: true
    add_column :child_supports, :stop_support_date, :datetime, null: true
  end
end
