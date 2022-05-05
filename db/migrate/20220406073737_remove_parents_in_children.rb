class RemoveParentsInChildren < ActiveRecord::Migration[6.0]
  def change
    change_table :children do |t|
      t.remove_references :parent1
      t.remove_references :parent2
    end
  end
end
