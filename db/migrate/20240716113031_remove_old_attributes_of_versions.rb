class RemoveOldAttributesOfVersions < ActiveRecord::Migration[6.1]
  def change
    remove_column :versions, :old_object
    remove_column :versions, :old_object_changes
  end
end
