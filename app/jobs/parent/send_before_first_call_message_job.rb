require 'sidekiq-scheduler'

class Parent::SendBeforeFirstCallMessageJob < ApplicationJob

  def perform(group_id, date)
    service = Parent::SendBeforeFirstCallMessageService.new(group_id: group_id, date: date).call
    Rollbar.error('Parent::SendBeforeFirstCallMessageService', group_id: group_id, errors: service.errors) if service.errors.any?
  end
end
