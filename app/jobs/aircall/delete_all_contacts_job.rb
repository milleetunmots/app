module Aircall
  class DeleteAllContactsJob < ApplicationJob

    def perform
      service = Aircall::DeleteContactService.new.call
      Rollbar.error(service.errors) if service.errors.any?
    end
  end
end
