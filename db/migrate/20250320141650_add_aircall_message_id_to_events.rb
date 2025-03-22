class AddAircallMessageIdToEvents < ActiveRecord::Migration[6.1]
  def change
    add_column :events, :aircall_message_id, :string
  end
end
