class AddParentToContactToChildren < ActiveRecord::Migration[6.0]
  def change
    add_column :children, :parent_to_contact_id, :integer
    add_index :children, :parent_to_contact_id

    Child.find_each do |child|
      # this should trigger the #define_parent_to_contact method
      child.save!
    end
  end
end
