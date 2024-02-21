require 'sidekiq-scheduler'

class Child::AddWaitingChildrenToGroupJob < ApplicationJob

  def perform
    Child.kept.where(group_status: 'waiting').order('birthdate ASC').find_each do |child|
      next unless child == child.youngest_sibling

      Child::AddToGroupService.new(child.id).call
    end
  end
end
