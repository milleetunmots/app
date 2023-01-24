class AddLocationToWorkshop < ActiveRecord::Migration[6.0]
  def change
    add_column :workshops, :location, :string
  end
end
