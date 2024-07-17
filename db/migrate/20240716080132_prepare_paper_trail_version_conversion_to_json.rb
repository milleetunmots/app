class PreparePaperTrailVersionConversionToJson < ActiveRecord::Migration[6.1]
  def change
    rename_column :versions, :object, :old_object
    rename_column :versions, :object_changes, :old_object_changes
    add_column :versions, :object, :jsonb
    add_column :versions, :object_changes, :jsonb
  end
end
