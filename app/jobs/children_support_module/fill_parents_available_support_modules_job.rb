class ChildrenSupportModule

  class FillParentsAvailableSupportModulesJob < ApplicationJob

    def perform(group_id, second_support_module)
      group = Group.find(group_id)
      current_module_index = group.support_module_programmed + 1
      support_module_sent_date = group.started_at + ((current_module_index - 2) * 8.weeks) + Group::ProgramService::MODULE_ZERO_DURATION
      Group::AddSiblingsToGroupService.new(group_id).call
      ChildSupport::FillParentsAvailableSupportModulesService.new(group_id, second_support_module, support_module_sent_date).call
    end
  end
end
