class ChildrenSupportModule
  class SelectModuleJob < ApplicationJob
    def perform(group_id, select_module_date)
      errors = {}
      group = Group.find(group_id)

      group.children.where(group_status: 'active').find_each do |child|
        next if child.siblings_on_same_group.count > 1 && child.child_support.current_child != child

        service = ChildSupport::SelectModuleService.new(
          child,
          select_module_date.sunday? ? select_module_date.next_day : select_module_date,
          '12:30'
        ).call
        errors[child.id] = service.errors if service.errors.any?
      end

      raise errors.to_json if errors.any?
    end
  end
end
