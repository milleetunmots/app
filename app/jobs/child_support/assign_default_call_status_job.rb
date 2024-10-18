require 'sidekiq-scheduler'
class ChildSupport
    class AssignDefaultCallStatusJob < ApplicationJob
      def perform(group_id, call_number)
        ChildSupport::AssignDefaultCallStatusService.new(group_id, call_number).call

        case call_number
        when 0
          service = ChildSupport::SendCallGoalsMessagesService.new(group_id, 0).call
          Rollbar.error("Send call0 first reminder messages service errors : #{service.errors}") if service.errors.any?
        when 1
          service = ChildSupport::SendCall0GoalsReminderMessagesService.new(group_id).call
          Rollbar.error("Send call0 goals second reminder messages service errors: #{service.errors}") if service.errors.any?
        when 3
          service = ChildSupport::SendCallGoalsMessagesService.new(group_id, 3).call
          Rollbar.error(service.errors) if service.errors.any?
        end
      end
    end
end
