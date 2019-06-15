class AddWhoToContactToChildren < ActiveRecord::Migration[6.0]
  def change
    add_column :children, :should_contact_parent1, :boolean, null: false, default: false
    add_column :children, :should_contact_parent2, :boolean, null: false, default: false
  end
end
