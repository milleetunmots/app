class RemoveIsLycamobileFromParent < ActiveRecord::Migration[6.0]
  def change
    remove_column :parents, :is_lycamobile
  end
end
