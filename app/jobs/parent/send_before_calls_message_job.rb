require 'sidekiq-scheduler'

class Parent::SendBeforeCallsMessageJob < ApplicationJob

  def perform
    service = Parent::SendBeforeCallsMessageService.new.call
    Rollbar.error('Parent::SendBeforeCallsMessageJob', errors: service.errors) if service.errors.any?
  end
end
