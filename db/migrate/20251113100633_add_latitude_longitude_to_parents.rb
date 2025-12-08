class AddLatitudeLongitudeToParents < ActiveRecord::Migration[6.1]
  def change
     add_column :parents, :latitude, :float
     add_column :parents, :longitude, :float
     add_index :parents, [:latitude, :longitude]
  end
end
