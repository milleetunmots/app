class AddOkForSolicitationToChildSupports < ActiveRecord::Migration[7.0]
  def change
    add_column :child_supports, :ok_for_solicitation, :boolean
  end
end
