require 'sidekiq-scheduler'

class Parent::SendNextDayScheduledCallReminderJob < ApplicationJob

  def perform
    service = Parent::SendNextDayScheduledCallReminderService.new.call
    Rollbar.error('Parent::SendNextDayScheduledCallReminderJob', errors: service.errors) if service.errors.any?
  end
end
