class PutChildrenInFamilies < ActiveRecord::Migration[6.0]
  def change
    Child.all.each do |child|
      next if child.family

      child.update!(family: Family.create!(parent1_id: child.parent1.id, parent2_id: child.parent2&.id, child_support_id: child.child_support&.id))
      child.siblings.each { |sibling| sibling.update!(family: child.family) }
    end
  end
end
