require 'sidekiq-scheduler'

class Group::DistributeChildSupportsToSupportersJob < ApplicationJob

  def perform(group, child_supports_count_by_supporter)
    Group::DistributeChildSupportsToSupportersService.new(group, child_supports_count_by_supporter).call
  end
end
