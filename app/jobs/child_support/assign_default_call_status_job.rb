require 'sidekiq-scheduler'
class ChildSupport
    class AssignDefaultCallStatusJob < ApplicationJob
      def perform(group_id, call_number)
        @group_id = group_id
        @call_number = call_number
        assign_default_call_status
        check_and_process_disengagement
        send_call_goals_messages
      end

      private

      def assign_default_call_status
        ChildSupport::AssignDefaultCallStatusService.new(@group_id, @call_number).call
      end

      def check_and_process_disengagement
        return if Group.find(@group_id).type_of_support == 'without_calls'

        Group::AddDisengagementTagService.new(@group_id, @call_number).call
        ChildSupport::ChildrenDisengagementService.new(@group_id).call
      end

      def send_call_goals_messages
        case @call_number
        when 0
          service = ChildSupport::SendCallGoalsMessagesService.new(@group_id, 0).call
          Rollbar.error("Send call0 first reminder messages service errors : #{service.errors}") if service.errors.flatten.any?
        when 1
          service = ChildSupport::SendCall0GoalsReminderMessagesService.new(@group_id).call
          Rollbar.error("Send call0 goals second reminder messages service errors: #{service.errors}") if service.errors.flatten.any?
        when 3
          service = ChildSupport::SendCallGoalsMessagesService.new(@group_id, 3).call
          Rollbar.error(service.errors) if service.errors.flatten.any?
        end
      end
    end
end
