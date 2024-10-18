require 'sidekiq-scheduler'

class Group::ProgramSmsToBilingualsJob < ApplicationJob

  def perform(group_id, first_sms_date)
    Group::ProgramSmsToBilingualsService.new(group_id, first_sms_date).call
  end
end
