module Aircall
  class ExportCallsTranscriptionService
    attr_reader :errors

    def initialize(started_at:)
      @aircall_calls = AircallCall.where.not(asset_url: nil)
                                  .where(raw_transcription_payload: nil)
                                  .where.not(transcription_not_found: Time.zone.today)
                                  .where('started_at >= ?', started_at)
      @errors = []
    end

    def call
      @aircall_calls.each do |aircall_call|
        begin
          transcription_service = RetrieveTranscriptionService.new(aircall_call.aircall_id).call
          if transcription_service.errors.any?
            aircall_call.update(transcription_not_found: Time.zone.today)
            @errors << transcription_service.errors.first
          else
            transcriptions = transcription_service.transcriptions
            aircall_call.update(raw_transcription_payload: transcriptions.to_json)
          end
        rescue StandardError => e
          aircall_call.update(transcription_not_found: Time.zone.today)
          @errors << "La récupération de la transcription de l'appel #{aircall_call.aircall_id} a échoué avec une erreur inattendue : #{e.message}"
        end
        sleep(2)
      end
      self
    end
  end
end
