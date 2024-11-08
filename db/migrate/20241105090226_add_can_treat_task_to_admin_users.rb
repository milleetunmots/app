class AddCanTreatTaskToAdminUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :admin_users, :can_treat_task, :boolean, null: false, default: false
  end
end
