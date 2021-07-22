class AddStatusAndMessageIdToEvents < ActiveRecord::Migration[6.0]
  def change
    add_column :events, :spot_hit_status, :integer
    add_column :events, :spot_hit_message_id, :string
  end
end
