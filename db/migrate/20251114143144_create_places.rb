class CreatePlaces < ActiveRecord::Migration[6.1]
  def change
    create_table :places do |t|
      t.string :place_type, null: false
      t.string :name, null: false
      t.text :address, null: false
      t.float :latitude
      t.float :longitude
      t.timestamps
    end
  end
end
