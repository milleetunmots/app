class AddMessageProviderToEvents < ActiveRecord::Migration[6.1]
  def change
    add_column :events, :message_provider, :string
    Event.sent_by_app_text_messages.update_all(message_provider: 'spot_hit')
  end
end
