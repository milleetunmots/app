class AddSpothitIdToMedia < ActiveRecord::Migration[6.0]
  def change
    add_column :media, :spot_hit_id, :string
  end
end
