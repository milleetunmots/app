require 'sidekiq-scheduler'

class Child::AddTagToChildrenJob < ApplicationJob

  def perform
    service = Child::AddTagToChildrenService.new.call
    Rollbar.error('Child::AddTagToChildrenService', errors: service.errors) if service.errors.any?
  end
end
