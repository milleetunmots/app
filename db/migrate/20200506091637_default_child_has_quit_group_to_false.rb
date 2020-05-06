class DefaultChildHasQuitGroupToFalse < ActiveRecord::Migration[6.0]
  def change
    Child.where(has_quit_group: nil).update_all(has_quit_group: false)
    change_column :children, :has_quit_group, :boolean, null: false, default: false
  end
end
