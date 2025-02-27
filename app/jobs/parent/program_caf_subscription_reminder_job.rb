require 'sidekiq-scheduler'

class Parent::ProgramCafSubscriptionReminderJob < ApplicationJob

  def perform(version_one: true)
    service = Parent::ProgramCafSubscriptionReminderService.new(version_one: version_one).call
    Rollbar.error('Parent::ProgramCafSubscriptionReminderJob', errors: service.errors) if service.errors.any?
  end
end
