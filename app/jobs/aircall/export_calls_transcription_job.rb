module Aircall
  class ExportCallsTranscriptionJob < ApplicationJob

    def perform(started_at:)
      service = Aircall::ExportCallsTranscriptionService.new(started_at: started_at).call
      Rollbar.error('ExportCallsTranscriptionService errors', errors: service.errors) if service.errors.any?
    end
  end
end
