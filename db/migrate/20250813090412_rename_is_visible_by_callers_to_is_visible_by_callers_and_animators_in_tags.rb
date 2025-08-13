class RenameIsVisibleByCallersToIsVisibleByCallersAndAnimatorsInTags < ActiveRecord::Migration[6.1]

  def up
    rename_column :tags, :is_visible_by_callers, :is_visible_by_callers_and_animators
  end

  def down
    rename_column :tags, :is_visible_by_callers_and_animators, :is_visible_by_callers
  end
end
