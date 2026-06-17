require 'sidekiq-scheduler'

class Parent::SendBeforeCallsMessageDailyJob < ApplicationJob

  def perform
    service = Parent::SendBeforeCallsMessageDailyService.new.call
    Rollbar.error('Parent::SendBeforeCallsMessageDailyJob', errors: service.errors) if service.errors.any?
  end
end
