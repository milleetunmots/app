require 'sidekiq-scheduler'

class Book::ImportBooksJob < ApplicationJob

  def perform
    service = Book::ImportFromAirtableService.new.call

    Rollbar.error(service.errors) if service.errors[:support_modules].any? || service.errors[:cover].any?
  end
end
