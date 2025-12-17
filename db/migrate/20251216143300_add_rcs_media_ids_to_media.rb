class AddRcsMediaIdsToMedia < ActiveRecord::Migration[6.1]
  def change
    add_column :media, :rcs_media1_id, :integer
    add_column :media, :rcs_media2_id, :integer
    add_column :media, :rcs_media3_id, :integer
  end
end
