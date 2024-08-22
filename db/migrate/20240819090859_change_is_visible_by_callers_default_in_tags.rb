class ChangeIsVisibleByCallersDefaultInTags < ActiveRecord::Migration[6.1]
  def change
    change_column_default :tags, :is_visible_by_callers, from: true, to: false
  end
end
