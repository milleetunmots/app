class ChildrenSupportModule
  class CheckToSendReminderJob < ApplicationJob
    def perform(children_support_module_ids, reminder_date, second_reminder = false)
      if children_support_module_ids.instance_of?(Array)
        children_support_module_ids.each do |children_support_module_id|
          send_reminder(children_support_module_id, reminder_date, second_reminder)
        end
      else
        send_reminder(children_support_module_ids, reminder_date, second_reminder)
      end
    end

    private

    def send_reminder(children_support_module_id, reminder_date, second_reminder = false)
      children_support_module = ChildrenSupportModule.find(children_support_module_id)
      unless children_support_module.support_module.present? || children_support_module.is_completed
        service = ChildrenSupportModule::SendReminder.new(children_support_module, reminder_date, second_reminder).call
        raise service.errors if service.errors.any?
      end
    end
  end
end
