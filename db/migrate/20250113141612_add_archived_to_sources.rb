class AddArchivedToSources < ActiveRecord::Migration[6.1]
  def change
    add_column :sources, :is_archived, :boolean, null: false, default: false
  end
end
