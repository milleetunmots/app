class AddDegreeAndDegreeInFranceToParent < ActiveRecord::Migration[6.0]
  def change
    add_column :parents, :degree, :string
    add_column :parents, :degree_in_france, :boolean
  end
end
