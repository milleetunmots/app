class AddExcludeToWorkshopToParents < ActiveRecord::Migration[6.1]
  def change
    add_column :parents, :exclude_to_workshop, :boolean, default: false
  end
end
