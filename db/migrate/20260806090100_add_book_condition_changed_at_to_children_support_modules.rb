class AddBookConditionChangedAtToChildrenSupportModules < ActiveRecord::Migration[7.0]

  def change
    add_column :children_support_modules, :book_condition_changed_at, :datetime
  end
end
