class AddIsVisibleByCallersToTags < ActiveRecord::Migration[6.1]
  def change
    add_column :tags, :is_visible_by_callers, :boolean, null: false, default: true
  end
end
