module Aircall
  class ExportCallsTranscriptionJob < ApplicationJob

    def perform
      service = Aircall::ExportCallsTranscriptionService.new.call
      Rollbar.error('ExportCallsTranscriptionService errors', errors: service.errors) if service.errors.any?
    end
  end
end
