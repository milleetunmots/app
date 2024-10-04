require 'sidekiq-scheduler'

class Book::ImportBooksJob < ApplicationJob

  def perform
    service = Book::ImportFromAirtableService.new.call

    Rollbar.error("Book::ImportFromAirtableService", :support_module => service.errors[:support_modules], :cover => service.errors[:cover]) if service.errors[:support_modules].any? || service.errors[:cover].any?
  end
end
