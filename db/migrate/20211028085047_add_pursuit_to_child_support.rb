class AddPursuitToChildSupport < ActiveRecord::Migration[6.0]
  def change
    add_column :child_supports, :pursuit, :boolean, null: false, default: false
  end
end
