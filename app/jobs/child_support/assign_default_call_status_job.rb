require 'sidekiq-scheduler'
class ChildSupport
    class AssignDefaultCallStatusJob < ApplicationJob
      def perform(group_id, call_number)
        ChildSupport::AssignDefaultCallStatusService.new(group_id, call_number).call
        if call_number == 1
          service = ChildSupport::SendCall0GoalsReminderMessagesService.new(group_id).call
          Rollbar.error(service.errors) if service.errors.any?
        end
        return unless call_number == 3

        service = ChildSupport::SendCallGoalsMessagesService.new(group_id, 3).call
        Rollbar.error(service.errors) if service.errors.any?
      end
    end
end
