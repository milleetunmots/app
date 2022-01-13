class AddLandToWorkshop < ActiveRecord::Migration[6.0]
  def change
    add_column :workshops, :land, :string
  end
end
