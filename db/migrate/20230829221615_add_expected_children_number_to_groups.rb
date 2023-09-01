class AddExpectedChildrenNumberToGroups < ActiveRecord::Migration[6.0]
  def change
    add_column :groups, :expected_children_number, :integer
  end
end
