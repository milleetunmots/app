module Aircall
  class CreateInsightCardService < Aircall::ApiBase

    attr_reader :errors

    def initialize(payload:)
      @errors = []
      @call_id = payload['id']
      @parent_phone_number = Phonelib.parse(payload['raw_digits']).e164
      @parent = Parent.find_by(phone_number: @parent_phone_number)
      @inbound = payload['direction'] == 'inbound'
      @insight_card =
        { contents: [
          { type: 'title', text: "Information d'appel" }
        ] }
    end

    def call
      add_call_informations_to_insight_card
      add_call_recording_to_insight_card
      response = http_client_with_auth.post(build_url(CALLS_ENDPOINT, "/#{@call_id}/insight_cards"), json: @insight_card)
      @errors << { message: "La création de l'aperçu d'appel a échoué : #{response.status.reason}", status: response.status.to_i, parent_phone_number: @parent_phone_number } unless response.status.success?
      self
    end

    protected

    def add_call_informations_to_insight_card
      return unless @inbound && @parent

      insight_card_content_text =
        if @parent&.current_child&.group
          "Appel #{@parent&.current_child&.group&.closest_call_session(Time.zone.today)}"
        else
          'Information indisponible'
        end
      @insight_card[:contents] << { type: 'shortText', label: "Session d'appel", text: insight_card_content_text }
    end

    def add_call_recording_to_insight_card
      return unless @parent&.current_child&.group_enable_calls_recording

      @insight_card[:contents] << { type: 'shortText', label: 'Enregistrement', text: 'Recommandé' }
    end
  end
end
