module Aircall
  class DeleteAllContactsJob < ApplicationJob

    def perform
      contacts = Aircall::ContactService.new.get.response
      contacts.each do |contact|
        Aircall::ContactService.new(id: contact['id']).delete
      end
    end
  end
end
