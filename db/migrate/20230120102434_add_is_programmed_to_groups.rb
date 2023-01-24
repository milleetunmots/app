class AddIsProgrammedToGroups < ActiveRecord::Migration[6.0]
  def change
    add_column :groups, :is_programmed, :boolean, null: false, default: false
  end
end
