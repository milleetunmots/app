class AddCancelUrlToScheduledCalls < ActiveRecord::Migration[7.0]
  def change
    add_column :scheduled_calls, :cancel_url, :string
  end
end
