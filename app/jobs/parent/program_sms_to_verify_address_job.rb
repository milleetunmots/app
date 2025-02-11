require 'sidekiq-scheduler'

class Parent::ProgramSmsToVerifyAddressJob < ApplicationJob

  def perform(group_id)
    service = Parent::ProgramSmsToVerifyAddressService.new(group_id).call
    Rollbar.error('Parent::ProgramSmsToVerifyAdressJob', errors: service.errors) if service.errors.any?
  end
end
