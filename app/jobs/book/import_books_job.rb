require 'sidekiq-scheduler'

class Book::ImportBooksJob < ApplicationJob

  def perform
    Book::ImportFromAirtableService.new.call
  end
end
