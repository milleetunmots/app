class ChildrenSupportModule

  class CreateChildrenSupportModuleJob < ApplicationJob

    def perform(group_id)
      errors = {}
      group = Group.find(group_id)

      group.children.includes(:parent1, :parent2, :child_support).where(group_status: 'active').find_each do |child|
        parent1_children_support_module = ChildrenSupportModule.create(child_id: child.id,
                                                                       parent_id: child.parent1.id,
                                                                       available_support_module_list: child.child_support.parent1_available_support_module_list)
        if child.parent2
          parent2_children_support_module = ChildrenSupportModule.create(child_id: child.id,
                                                                         parent_id: child.parent2.id,
                                                                         available_support_module_list: child.child_support.parent2_available_support_module_list)
        end
        if parent1_children_support_module.errors.any? || parent2_children_support_module&.errors&.any?
          errors[child.id] = handle_errors([parent1_children_support_module, parent2_children_support_module])
        end
      end

      raise errors.to_json if errors.any?
    end

    private

    def handle_errors(children_support_modules)
      errors = []

      children_support_modules.compact.each do |csm|
        errors << csm.errors if csm.errors.any?
      end

      errors
    end
  end
end
