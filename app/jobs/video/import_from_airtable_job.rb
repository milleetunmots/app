require 'sidekiq-scheduler'

class Video::ImportFromAirtableJob < ApplicationJob

  def perform
    Video::ImportFromAirtableService.new.call
  end
end
