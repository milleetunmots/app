class AddLandToWorkshop < ActiveRecord::Migration[6.0]
  def change
    add_column :workshops, :workshop_land, :string
  end
end
