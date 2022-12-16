class DropShouldContactParentFromChildren < ActiveRecord::Migration[6.0]
  def change
    Parent.includes(:parent1_children).where(children: {should_contact_parent1: false})
          .references(:parent1_children).update_all(should_be_contacted: false)
    Parent.includes(:parent2_children).where(children: {should_contact_parent2: false})
          .references(:parent2_children).update_all(should_be_contacted: false)

    remove_column :children, :should_contact_parent1, :boolean
    remove_column :children, :should_contact_parent2, :boolean
  end
end
