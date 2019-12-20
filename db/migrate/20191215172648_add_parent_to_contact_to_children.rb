class AddParentToContactToChildren < ActiveRecord::Migration[6.0]
  def change
    add_column :children, :parent_to_contact_id, :integer
    add_index :children, :parent_to_contact_id
  end
end
