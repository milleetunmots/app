class ChildrenSupportModule

  class FillParentsAvailableSupportModulesJob < ApplicationJob

    def perform(group_id, second_support_module)
      Group::AddSiblingsToGroupService.new(group_id).call
      ChildSupport::FillParentsAvailableSupportModulesService.new(group_id, second_support_module).call
    end
  end
end
