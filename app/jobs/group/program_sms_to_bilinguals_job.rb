require 'sidekiq-scheduler'

class Group::ProgramSmsToBilingualsJob < ApplicationJob

  def perform(group_id, first_sms_date)
    Group::ProgramSmsToBilingualsService.new(group_id, first_sms_date).call

    service = ChildSupport::SendCallGoalsMessagesService.new(group_id, 0).call
    Rollbar.error(service.errors) if service.errors.any?
  end
end
