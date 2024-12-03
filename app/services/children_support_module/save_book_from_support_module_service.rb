class ChildrenSupportModule
  class SaveBookFromSupportModuleService

		def initialize(group_id:, module_index:)
			@group_id = group_id
			@module_index = module_index
    end

    def call
			group = Group.find(group_id)
			children_ids = group.children.ids
			# get not_programmed + with_support_module CSM for the group
			chosen_modules = ChildrenSupportModule.chosen_modules_for_group(@group_id)
			chosen_modules = chosen_modules.uniq { |csm| [csm.child_id, csm.parent_id] }
			# SQL query because AR update_call can't handle joins
			chosen_modules_ids = chosen_modules.pluck(:id).join(',')
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
