class RemoveLandFromChild < ActiveRecord::Migration[6.0]
  def change
    remove_column :children, :land
  end
end
