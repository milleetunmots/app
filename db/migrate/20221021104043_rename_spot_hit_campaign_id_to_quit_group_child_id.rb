class RenameSpotHitCampaignIdToQuitGroupChildId < ActiveRecord::Migration[6.0]
  def change
    remove_column :events, :spot_hit_campaign_id
    add_reference :events, :quit_group_child
  end
end
