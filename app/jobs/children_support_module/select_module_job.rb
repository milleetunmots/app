class ChildrenSupportModule

  class SelectModuleJob < ApplicationJob

    def perform(group_id, select_module_date, module_index)
      errors = {}
      group = Group.find(group_id)
      # module_index starts with 1
      # so if module_index == 3 it means this is Module 2 (that comes after Module 0 and 1)
      children = if module_index.eql?(3) && group.with_module_zero?
                   group.children.where(group_status: 'active').joins(:child_support).where(child_supports: { call2_status: ['KO', 'Ne pas appeler'] })
                 else
                   group.children.where(group_status: 'active')
                 end

      children.each do |child|
        unless child.child_support
          errors["child: #{child.id}"] = "Cet enfant n'a pas de fiche de suivi"
          next
        end

        next if child.siblings_on_same_group.count > 1 && child.child_support.current_child != child

        child.child_support.update(
          parent1_available_support_module_list: child.child_support.parent1_available_support_module_list&.reject(&:blank?)&.first(3),
          parent2_available_support_module_list: child.child_support.parent2_available_support_module_list&.reject(&:blank?)&.first(3)
        )
        service = ChildSupport::SelectModuleService.new(
          child,
          select_module_date.sunday? ? select_module_date.next_day : select_module_date,
          '12:30',
          module_index
        ).call
        errors[child.id] = service.errors if service.errors.any?
      end

      raise errors.to_json if errors.any?
    end
  end
end
