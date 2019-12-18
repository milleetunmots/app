class DropChildrenParentToContact < ActiveRecord::Migration[6.0]
  def change
    remove_column :children, :parent_to_contact_id
  end
end
