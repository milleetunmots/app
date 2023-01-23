class ChildrenSupportModule
  class ProgramSupportModuleSmsJob < ApplicationJob
    def perform(group_id)
      errors = {}
      group = Group.find(group_id)
      children_support_module_ids = ChildrenSupportModule.where(child_id: group.children.where(group_status: "active").ids)

      service = ChildSupport::ProgramChosenModulesService.new(children_support_module_ids)
      errors[group.id] = service.errors if service.errors.any?


      raise errors.to_json if errors.any?
    end
  end
end
