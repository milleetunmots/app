require 'sidekiq-scheduler'

class Book::ImportBooksJob < ApplicationJob

  def perform
    sync_service = SupportModule::SyncAirtableIdsService.new.call

    Rollbar.error("SupportModule::SyncAirtableIdsService", :support_modules => sync_service.errors) if sync_service.errors.any?

    service = Book::ImportFromAirtableService.new.call

    Rollbar.error("Book::ImportFromAirtableService", :support_module => service.errors[:support_modules], :cover => service.errors[:cover]) if service.errors[:support_modules].any? || service.errors[:cover].any?
  end
end
