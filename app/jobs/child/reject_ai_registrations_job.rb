require 'sidekiq-scheduler'
class Child

  class RejectAiRegistrationsJob < ApplicationJob

    def perform
      Child::RejectAiRegistrationsService.new.call
    end
  end
end
