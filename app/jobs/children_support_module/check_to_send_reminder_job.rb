class ChildrenSupportModule
  class CheckToSendReminderJob < ApplicationJob
    def perform(children_support_module_id, reminder_date)
      children_support_module = ChildrenSupportModule.find(children_support_module_id)

      unless children_support_module.support_module.present? || children_support_module.is_completed
        service = ChildrenSupportModule::SendReminder.new(children_support_module, reminder_date).call
        raise service.errors if service.errors.any?
      end
    end
  end
end
