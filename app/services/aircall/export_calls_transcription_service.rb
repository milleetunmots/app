module Aircall
  class ExportCallsTranscriptionService
    attr_reader :errors

    def initialize
      @aircall_calls = AircallCall.where.not(asset_url: nil)
                                  .where(raw_transcription_payload: nil)
                                  .where(transcription_not_found: nil)
                                  .where('started_at >= ?', Date.new(2025, 1, 1))
      @errors = []
    end

    def call
      @aircall_calls.each do |aircall_call|
        begin
          transcription_service = RetrieveTranscriptionService.new(aircall_call.aircall_id).call
          sleep(2)
          transcriptions = transcription_service.transcriptions
          aircall_call.update(raw_transcription_payload: transcriptions.to_json)
        rescue StandardError => e
          aircall_call.update(transcription_not_found: Time.zone.today)
          @errors << { message: "Erreur lors de l'export des transcriptions", erreurs: e.message }
        end
      end
      self
    end
  end
end
