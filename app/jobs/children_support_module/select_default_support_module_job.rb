class ChildrenSupportModule

  class SelectDefaultSupportModuleJob < ApplicationJob

    def perform(group_id)
      group = Group.find(group_id)

      ChildSupport::ChildrenDisengagementService.new(group_id).call
      ChildrenSupportModule::CreateChildrenSupportModuleService.new(group_id).call if any_current_child_without_children_support_module?(group)
      ChildrenSupportModule::SelectDefaultSupportModuleService.new(group.id).call
    end

    private

    def active_current_children_with_child_support(group)
      active_children_with_child_support = group.children.where(group_status: 'active').ids
      ChildSupport.includes(:children).where(children: { id: active_children_with_child_support }).map { |child_support| child_support.current_child.id }
    end

    def any_current_child_without_children_support_module?(group)
      current_child_without_children_support_module = []
      current_support_module_index = group.support_module_programmed + 1
      active_current_children_with_child_support(group).each do |child_id|
        children_support_module = ChildrenSupportModule.find_by(child_id: child_id, module_index: current_support_module_index)
        current_child_without_children_support_module << child_id if children_support_module.nil?
      end
      current_child_without_children_support_module.any?
    end
  end
end
