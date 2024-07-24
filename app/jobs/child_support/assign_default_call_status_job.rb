require 'sidekiq-scheduler'
class ChildSupport
    class AssignDefaultCallStatusJob < ApplicationJob
      def perform(group_id, call_number)
        ChildSupport::AssignDefaultCallStatusService.new(group_id, call_number).call
        service = ChildSupport::SendCall3GoalsMessagesService.new(group_id).call if call_number == 3
        Rollbar.error(service.errors) if service.errors.any?
      end
    end
end
