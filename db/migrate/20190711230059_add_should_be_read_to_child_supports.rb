class AddShouldBeReadToChildSupports < ActiveRecord::Migration[6.0]
  def change
    add_column :child_supports, :should_be_read, :boolean
    add_index :child_supports, :should_be_read
  end
end
