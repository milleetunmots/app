class RemoveShouldBeReadFromChildSupports < ActiveRecord::Migration[7.0]
  def change
    remove_index :child_supports, :should_be_read
    remove_column :child_supports, :should_be_read, :boolean
  end
end
