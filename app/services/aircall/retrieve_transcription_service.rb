module Aircall
  class RetrieveTranscriptionService < Aircall::ApiBase

    attr_reader :errors, :transcriptions

    def initialize(call_id)
      @call_id = call_id
      @url = "#{BASE_URL}#{CALLS_ENDPOINT}/#{call_id}/transcription"
      @transcriptions = []
      @errors = []
    end

    def call
      return self unless ENV['AIRCALL_ENABLED']

      response = http_client_with_auth.get(@url)
      if response.status.success?
        body = JSON.parse(response.body)
        @transcriptions = body['transcription']['content']['utterances']
      else
        @errors << { message: "La récupération de la transcription de l'appel #{@call_id} a échoué : #{response.status.reason}", status: response.status.to_i }
      end
      self
    end

  end
end
