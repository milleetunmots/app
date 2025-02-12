require 'sidekiq-scheduler'

class Parent::ProgramSmsToVerifyAddressJob < ApplicationJob

  def perform(group_id, program_sms_date)
    service = Parent::ProgramSmsToVerifyAddressService.new(group_id, program_sms_date).call
    Rollbar.error('Parent::ProgramSmsToVerifyAddressJob', errors: service.errors) if service.errors.any?
  end
end
