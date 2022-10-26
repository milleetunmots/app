class RemoveShouldContactParentFromChild < ActiveRecord::Migration[6.0]
  def change
    remove_column :children, :should_contact_parent1
    remove_column :children, :should_contact_parent2
  end
end
