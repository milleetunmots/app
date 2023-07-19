require 'sidekiq-scheduler'

class Bubble::ImportModelsJob < ApplicationJob

  def perform
    Bubble::ImportBubbleModelsService.call
  end
end
