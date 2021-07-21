class AddStatusAndMessageIdToEvents < ActiveRecord::Migration[6.0]
  def change
    add_column :events, :status, :integer
    add_column :events, :message_id, :string
  end
end
