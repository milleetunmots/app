class AddAirtableIdToSupportModules < ActiveRecord::Migration[7.0]
  def change
    add_column :support_modules, :airtable_id, :string
    add_index :support_modules, :airtable_id, unique: true
  end
end
