class ChildrenSupportModule

  class SelectModuleJob < ApplicationJob

    def perform(group_id, select_module_date, second_support_module = false)
      errors = {}
      group = Group.find(group_id)
      if second_support_module
        children = group.children.where(group_status: 'active').where(child_supports: { call2_status: ['KO', 'Ne pas appeler'] })
        children.update(
          parent1_available_support_module_list: parent1_available_support_module_list&.reject(&:blank?)&.first(3),
          parent2_available_support_module_list: parent2_available_support_module_list&.reject(&:blank?)&.first(3)
        )
      else
        children = group.children.where(group_status: 'active')
      end

      children.find_each do |child|
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
