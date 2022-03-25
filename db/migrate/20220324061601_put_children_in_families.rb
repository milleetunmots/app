class PutChildrenInFamilies < ActiveRecord::Migration[6.0]
  def change
    Child.all.each do |child|
      next if child.family

      child.update!(family: Family.create!(parent1: child.parent1, parent2: child.parent2, child_support: child.child_support))
      child.siblings.each { |sibling| sibling.update!(family: child.family) }
    end
  end
end
