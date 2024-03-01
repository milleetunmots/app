require 'sidekiq-scheduler'
class Child
    class StopUnassignedNumberJob < ApplicationJob
      def perform
        Child::StopUnassignedNumberService.new.call
    end
  end
end
