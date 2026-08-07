require 'sidekiq-scheduler'

class Book::EnsureUpcomingShipmentDatesJob < ApplicationJob

  def perform
    BookShipmentDate.create!(date: BookShipmentDate.next_suggested_date) while BookShipmentDate.upcoming.count < 2
  end
end
