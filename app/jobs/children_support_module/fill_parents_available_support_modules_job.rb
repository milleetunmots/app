class ChildrenSupportModule

  class FillParentsAvailableSupportModulesJob < ApplicationJob

    def perform(group_id, second_support_module)
      ChildSupport::FillParentsAvailableSupportModulesService.new(group_id, second_support_module).call
    end
  end
end
