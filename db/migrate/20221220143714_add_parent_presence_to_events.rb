class AddParentPresenceToEvents < ActiveRecord::Migration[6.0]
  def change
    add_column :events, :parent_presence, :string
  end
end
