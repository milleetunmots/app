class ChildrenSupportModule

  class CreateChildrenSupportModuleJob < ApplicationJob

    def perform(group_id)
      ChildrenSupportModule::CreateChildrenSupportModuleService.new(group_id).call
    end
  end
end
