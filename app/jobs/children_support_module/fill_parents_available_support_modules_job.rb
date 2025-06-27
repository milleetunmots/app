class ChildrenSupportModule

  class FillParentsAvailableSupportModulesJob < ApplicationJob

    def perform(group_id, module_index)
      Group::AddSiblingsToGroupService.new(group_id).call
      ChildSupport::FillParentsAvailableSupportModulesService.new(group_id, module_index).call
    end
  end
end
