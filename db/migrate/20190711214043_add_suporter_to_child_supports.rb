class AddSuporterToChildSupports < ActiveRecord::Migration[6.0]
  def change
    add_reference :child_supports, :supporter, foreign_key: { to_table: :admin_users }
    ChildSupport.update_all(supporter_id: AdminUser.first.id)
  end
end
