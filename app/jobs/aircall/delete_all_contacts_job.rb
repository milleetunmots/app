module Aircall
  class DeleteAllContactsJob < ApplicationJob

    def perform
      Aircall::DeleteContactService.new.call
    end
  end
end
