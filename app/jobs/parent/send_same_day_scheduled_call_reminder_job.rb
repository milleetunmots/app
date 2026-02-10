require 'sidekiq-scheduler'

class Parent::SendSameDayScheduledCallReminderJob < ApplicationJob

  def perform
    service = Parent::SendSameDayScheduledCallReminderService.new.call
    Rollbar.error('Parent::SendSameDayScheduledCallReminderJob', errors: service.errors) if service.errors.any?
  end
end
