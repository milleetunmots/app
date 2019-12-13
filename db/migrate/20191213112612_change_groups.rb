class ChangeGroups < ActiveRecord::Migration[6.0]
  def change
    drop_table :children_groups
    add_reference :children, :group, index: true
    add_column :children, :has_quit_group, :boolean

    # clean history
    PaperTrail::Version.where(item_type: 'ChildrenGroup').delete_all
  end
end
