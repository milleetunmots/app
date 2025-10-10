require 'sidekiq-scheduler'
class ChildSupport
    class AssignDefaultCallStatusJob < ApplicationJob
      def perform(group_id, call_number)
        @group_id = group_id
        @call_number = call_number
        @parent_link = {}
        assign_default_call_status
        check_and_process_disengagement
        send_call_goals_messages
      end

      private

      def assign_default_call_status
        ChildSupport::AssignDefaultCallStatusService.new(@group_id, @call_number).call
      end

      def create_parent_link(parent_id)
        link = Rails.application.routes.url_helpers.admin_parent_url(id: parent_id)
        @parent_link[:"#{link}"] = link
      end

      def check_and_process_disengagement
        group = Group.find(@group_id)
        return if group.type_of_support == 'without_calls'

        Group::AddDisengagementTagService.new(@group_id, @call_number).call
        disengagement_service = ChildSupport::ChildrenDisengagementService.new(@group_id).call
        return unless disengagement_service.errors.flatten.any?

        disengagement_service.parent_ids.each { |parent_id| create_parent_link(parent_id.gsub('parent.', '')) }
        description_text = "Les parents suivants ont été désengagés : "
        @parent_link.each { |name, link| description_text << "<br>#{ActionController::Base.helpers.link_to(name, link, target: '_blank', class: 'blue')}" }
        description_text = "#{description_text}<br>Certains d'entre eux n'ont pas reçu le message de désengagement."
        description_text = "#{description_text}<br>#{disengagement_service.errors.join('<br>')}"
        Task::CreateAutomaticTaskService.new(
          title: "Erreur lors de l'envoi du message de désengagement à certaines familles de la cohorte #{group.name}",
          description: description_text
        ).call
        Rollbar.error('ChildSupport::ChildrenDisengagementService', errors: disengagement_service.errors, group: group.id, parent_ids: disengagement_service.parent_ids.map { |parent_id| parent_id.gsub('parent.', '')})
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
