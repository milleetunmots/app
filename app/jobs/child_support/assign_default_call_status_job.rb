require 'sidekiq-scheduler'
class ChildSupport
    class AssignDefaultCallStatusJob < ApplicationJob
      def perform(group_id, call_number)
        ChildSupport::AssignDefaultCallStatusService.new(group_id, call_number).call
        ChildSupport::SendCall3GoalsMessagesService.new(group_id).call if call_number == 3
    end
  end
end
