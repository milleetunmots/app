class ChildrenSupportModule

  class FillParentsAvailableSupportModulesJob < ApplicationJob

    def perform(group_id, second_support_module)
      Group::StopSupportService.new(group_id, end_of_support: false)
      ChildSupport::FillParentsAvailableSupportModulesService.new(group_id, second_support_module).call
    end
  end
end
