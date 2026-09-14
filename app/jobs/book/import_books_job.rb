require 'sidekiq-scheduler'

class Book::ImportBooksJob < ApplicationJob

  def perform
    # Les liens de consultation sont indépendants des associations aux livres.
    content_sync = SupportModule::SyncAirtableContentIdsService.new.call
    Rollbar.error('SupportModule::SyncAirtableContentIdsService', errors: content_sync.errors) if content_sync.errors.any?

    sync_service = SupportModule::SyncAirtableIdsService.new.call

    if sync_service.errors.any?
      Rollbar.error("SupportModule::SyncAirtableIdsService", :support_modules => sync_service.errors)
      return
    end

    service = Book::ImportFromAirtableService.new.call

    Rollbar.error("Book::ImportFromAirtableService", :support_module => service.errors[:support_modules], :cover => service.errors[:cover]) if service.errors[:support_modules].any? || service.errors[:cover].any?
  end
end
