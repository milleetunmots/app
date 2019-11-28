class AddSuporterToChildSupports < ActiveRecord::Migration[6.0]
  def change
    add_reference :child_supports, :supporter, foreign_key: { to_table: :admin_users }
  end
end
