class AddAirtableIdToVideos < ActiveRecord::Migration[6.1]
  def change
    add_column :media, :airtable_id, :string
    add_index :media, :airtable_id, unique: true
  end
end
