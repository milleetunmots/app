module Aircall
  class SyncContactsJob < ApplicationJob

    def perform
      service = Aircall::SyncContactsService.new.call
      Rollbar.error(service.errors) if service.errors.any?
    end
  end
end
