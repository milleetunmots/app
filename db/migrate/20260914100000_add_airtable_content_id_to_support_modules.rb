class AddAirtableContentIdToSupportModules < ActiveRecord::Migration[7.0]
  def change
    add_column :support_modules, :airtable_content_id, :string
  end
end
