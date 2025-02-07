require 'sidekiq-scheduler'

class Parent::ProgramSmsToVerifyAdressJob < ApplicationJob

  def perform(group_id)
    service = Parent::ProgramSmsToVerifyAdressService.new(group_id).call
    Rollbar.error('Parent::ProgramSmsToVerifyAdressJob', errors: service.errors) if service.errors.any?
  end
end
