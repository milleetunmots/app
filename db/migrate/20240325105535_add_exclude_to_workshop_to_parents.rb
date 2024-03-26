class AddExcludeToWorkshopToParents < ActiveRecord::Migration[6.1]
  def change
    add_column :parents, :is_excluded_from_workshop, :boolean, default: false
  end
end
