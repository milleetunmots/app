require 'sidekiq-scheduler'

class Parent::CheckAddressReminderJob < ApplicationJob

  def perform
    service = Parent::CheckAddressReminderService.new.call
    Rollbar.error('Parent::CheckAddressReminderJob', errors: service.errors) if service.errors.any?
  end
end
