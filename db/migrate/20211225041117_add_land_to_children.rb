class AddLandToChildren < ActiveRecord::Migration[6.0]
  def change
    add_column :children, :land, :string, default: "France"
  end
end
