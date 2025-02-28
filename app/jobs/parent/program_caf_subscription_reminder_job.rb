require 'sidekiq-scheduler'

class Parent::ProgramCafSubscriptionReminderJob < ApplicationJob

  def perform(date_time:, message_v1: true)
    service = Parent::ProgramCafSubscriptionReminderService.new(date_time: date_time, message_v1: message_v1).call
    Rollbar.error('Parent::ProgramCafSubscriptionReminderJob', errors: service.errors) if service.errors.any?
  end
end
