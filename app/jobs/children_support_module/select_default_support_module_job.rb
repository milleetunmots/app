class ChildrenSupportModule

  class SelectDefaultSupportModuleJob < ApplicationJob

    def perform(group_id)
      ChildSupport::ChildrenDisengagementService.new(group_id).call
      ChildrenSupportModule::SelectDefaultSupportModuleService.new(group_id).call
    end
  end
end
