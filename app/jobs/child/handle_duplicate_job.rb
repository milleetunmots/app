require 'sidekiq-scheduler'
class Child
  class HandleDuplicateJob < ApplicationJob
    def perform
      Child::HandleDuplicateService.new.call
    end
  end
end
