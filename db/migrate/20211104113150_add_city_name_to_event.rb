class AddCityNameToEvent < ActiveRecord::Migration[6.0]
  def change
    add_column :events, :city_name, :string
  end
end
