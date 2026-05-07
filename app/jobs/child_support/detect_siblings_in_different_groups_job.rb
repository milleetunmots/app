require 'sidekiq-scheduler'
class ChildSupport
  class DetectSiblingsInDifferentGroupsJob < ApplicationJob
    def perform
      ChildSupport::DetectSiblingsInDifferentGroupsService.new.call
    end
  end
end
