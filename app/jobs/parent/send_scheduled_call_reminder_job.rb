require 'sidekiq-scheduler'

class Parent::SendScheduledCallReminderJob < ApplicationJob

  def perform(parent_id:, scheduled_call_id:, message:)
    service = Parent::SendScheduledCallReminderService.new(
      parent_id: parent_id,
      scheduled_call_id: scheduled_call_id,
      message: message
    ).call
    Rollbar.error('Parent::SendScheduledCallReminderJob', errors: service.errors) if service.errors.any?
  end
end
