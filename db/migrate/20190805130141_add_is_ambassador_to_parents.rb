class AddIsAmbassadorToParents < ActiveRecord::Migration[6.0]
  def change
    add_column :parents, :is_ambassador, :boolean
    add_index :parents, :is_ambassador
  end
end
