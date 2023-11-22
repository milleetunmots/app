class ChildrenSupportModule
  class VerifyAvailableModulesTaskJob < ApplicationJob
    def perform(group_id)
      ChildSupport::VerifyAvailableModulesTaskService.new(group_id).call
    end
  end
end
