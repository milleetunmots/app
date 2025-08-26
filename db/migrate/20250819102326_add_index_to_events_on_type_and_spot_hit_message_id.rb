class AddIndexToEventsOnTypeAndSpotHitMessageId < ActiveRecord::Migration[6.1]
  def change
    add_index :events, [:type, :spot_hit_message_id]
  end
end
