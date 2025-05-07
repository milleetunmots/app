require 'sidekiq-scheduler'

class Child::SendEvalMessageJob < ApplicationJob

  def perform
    service = Child::SendEvalMessageService.new.call
    Rollbar.error('Child::SendEvalMessageService', errors: service.errors) if service.errors.any?
  end
end
