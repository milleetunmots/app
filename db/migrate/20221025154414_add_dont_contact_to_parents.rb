class AddDontContactToParents < ActiveRecord::Migration[6.0]
  def change
    add_column :parents, :dont_contact, :boolean, default: false

    Child.where(should_contact_parent1: false).each do |child|
      child.parent1.update!(dont_contact: true)
    end

    Child.where(should_contact_parent2: false).each do |child|
      child.parent2&.update!(dont_contact: true)
    end
  end
end
