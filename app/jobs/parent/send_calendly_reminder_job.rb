require 'sidekiq-scheduler'

class Parent::SendCalendlyReminderJob < ApplicationJob

  def perform
    service = Parent::SendCalendlyReminderService.new.call
    Rollbar.error('Parent::SendCalendlyReminderJob', errors: service.errors) if service.errors.any?
  end
end
