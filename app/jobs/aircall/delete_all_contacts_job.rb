module Aircall
  class DeleteAllContactsJob < ApplicationJob

    def perform
      service = Aircall::DeleteContactService.new(delete_all: true).call
      Rollbar.error(service.errors) if service.errors.any?
    end
  end
end
