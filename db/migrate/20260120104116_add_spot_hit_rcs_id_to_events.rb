class AddSpotHitRcsIdToEvents < ActiveRecord::Migration[7.0]
  def change
    add_column :events, :spot_hit_rcs_id, :string
    add_index :events, :spot_hit_rcs_id
  end
end
