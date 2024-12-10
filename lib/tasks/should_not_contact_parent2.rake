namespace :child do
  desc 'Handle children with the same parent twice'
  task should_not_contact_parent2: :environment do
    Child.joins(:parent1, :parent2).select { |child| child.parent1.phone_number == child.parent2.phone_number }.each do |child|
      child.update_column(:should_contact_parent2, false)
    end
  end
end
