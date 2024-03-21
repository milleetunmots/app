require 'sidekiq-scheduler'
class ChildSupport
    class AssignDefaultCallStatusJob < ApplicationJob
      def perform(group_id, call_number)
        ChildSupport::AssignDefaultCallStatusService.new(group_id, call_number).call
    end
  end
end
