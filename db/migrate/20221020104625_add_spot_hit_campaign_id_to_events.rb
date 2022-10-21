class AddSpotHitCampaignIdToEvents < ActiveRecord::Migration[6.0]
  def change
    add_column :events, :spot_hit_campaign_id, :string
  end
end
