class ChildrenSupportModule
  class CheckToSendReminder < ApplicationJob
    def perform(children_support_module_id)
      children_support_module = ChildrenSupportModule.find(children_support_module_id)

      unless children_support_module.is_completed
        service = ChildrenSupportModule::SendReminder.new(children_support_module).call
        raise service.errors if service.errors.any?
      end
    end
  end
end
