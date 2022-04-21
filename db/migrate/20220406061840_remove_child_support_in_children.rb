class RemoveChildSupportInChildren < ActiveRecord::Migration[6.0]
  def change
    change_table :children do |t|
      t.remove_references :child_support
    end
  end
end
