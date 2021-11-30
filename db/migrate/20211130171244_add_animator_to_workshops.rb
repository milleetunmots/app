class AddAnimatorToWorkshops < ActiveRecord::Migration[6.0]
  def change
    add_reference :workshops, :animator, foreign_key: {to_table: :admin_users}
  end
end
