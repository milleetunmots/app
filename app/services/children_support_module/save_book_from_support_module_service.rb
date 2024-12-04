class ChildrenSupportModule
  class SaveBookFromSupportModuleService
		# Support module has books associated, but these can change over time
		# So we save the book associated to a chosen module on the corresponding CSM before we send them

		def initialize(group_id:)
			@group_id = group_id
    end

    def call
			# get not_programmed + with_support_module CSM for the group (only parent1 choices)
			chosen_modules = ChildrenSupportModule.chosen_modules_for_group(@group_id)
			chosen_modules = chosen_modules.uniq { |csm| [csm.child_id, csm.parent_id] }
			# keep CSM of active children only
			chosen_modules_ids = ChildrenSupportModule.joins(:child)
													 .where(id: chosen_modules)
													 .where(children: { group_status: 'active' }).ids.join(',')
			# SQL query because AR update_call can't handle joins
			ActiveRecord::Base.connection.execute(<<-SQL)
				UPDATE children_support_modules
				SET book_id = support_modules.book_id
				FROM support_modules
				WHERE children_support_modules.support_module_id = support_modules.id
				AND children_support_modules.id IN (#{chosen_modules_ids});
			SQL
		end
  end
end
