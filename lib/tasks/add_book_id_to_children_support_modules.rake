namespace :books do
  desc 'Retroactively assign books sent to families to previous children support modules'
  task add_book_id_to_children_support_modules: :environment do
		group_ids = Group.started.where('started_at > ?', Date.new(2024, 5, 1)).ids
		unless group_ids
			puts "Error: no groups"
			return
		end
		chosen_modules = ChildrenSupportModule.chosen_modules_for_group(group_ids, true)
		unless chosen_modules.any?
			puts "Error: no children support modules"
			return
		end

		chosen_modules_ids = chosen_modules.pluck(:id).join(',')
		ActiveRecord::Base.connection.execute(<<-SQL)
			UPDATE children_support_modules
			SET book_id = support_modules.book_id
			FROM support_modules
			WHERE children_support_modules.support_module_id = support_modules.id
			AND children_support_modules.id IN (#{chosen_modules_ids});
		SQL
		puts "Update completed !"
  end
end
