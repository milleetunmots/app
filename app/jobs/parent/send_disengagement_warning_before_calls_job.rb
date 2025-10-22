require 'sidekiq-scheduler'

class Parent::SendDisengagementWarningBeforeCallsJob < ApplicationJob

  def perform
    service = Parent::SendDisengagementWarningBeforeCallsService.new.call
    Rollbar.error('Parent::SendDisengagementWarningBeforeCallsJob', errors: service.errors) if service.errors.any?
  end
end
