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

    report_import_errors(service.errors)
  end

  private

  def report_import_errors(import_errors)
    return if import_errors.each_value.all?(&:empty?)

    Rollbar.error('Book::ImportFromAirtableService',
                  support_module: import_errors[:support_modules],
                  cover: import_errors[:cover],
                  interior_photos: import_errors[:interior_photos])
  end
end
