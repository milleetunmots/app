class ChildrenSupportModule
  class CheckCreditsForGroupJob < ApplicationJob
    def perform(group_id)
      errors = {}
      group = Group.find(group_id)

      children_support_module_ids = ChildrenSupportModule.where(child_id: group.children.where(group_status: "active").ids)

      check_service = ChildrenSupportModule::CheckCreditsService.new(children_support_module_ids).call
      raise check_service.errors.to_json if check_service.errors.any?
    end
  end
end
