require 'sidekiq-scheduler'

class Child::AddEvalTagToChildrenJob < ApplicationJob

  def perform
    service = Child::AddEvalTagToChildrenService.new.call
    Rollbar.error('Child::AddEvalTagToChildrenService', errors: service.errors) if service.errors.any?
  end
end
