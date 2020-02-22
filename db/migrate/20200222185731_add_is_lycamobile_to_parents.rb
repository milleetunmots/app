class AddIsLycamobileToParents < ActiveRecord::Migration[6.0]
  def change
    add_column :parents, :is_lycamobile, :boolean
  end
end
