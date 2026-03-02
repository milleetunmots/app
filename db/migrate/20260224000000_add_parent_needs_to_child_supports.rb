class AddParentNeedsToChildSupports < ActiveRecord::Migration[6.1]
  def change
    add_column :child_supports, :parent_needs, :text
  end
end
