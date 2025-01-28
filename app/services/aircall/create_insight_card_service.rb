module Aircall
  class CreateInsightCardService < Aircall::ApiBase

    attr_reader :errors

    def initialize(payload:)
      @errors = []
      @call_id = payload['id']
      @parent_phone_number = Phonelib.parse(payload['raw_digits']).e164
      @inbound = payload['direction'] == 'inbound'
    end

    def call
      return self unless @inbound

      response = http_client_with_auth.post(build_url(CALLS_ENDPOINT, "/#{@call_id}/insight_cards"), json: insight_card_contain)
      unless response.status.success?
        @errors << { message: "La création de l'aperçu d'appel a échoué : #{response.status.reason}", status: response.status.to_i, parent_phone_number: @parent_phone_number }
      end
      self
    end

    private

    def insight_card_contain
      { contents:
        [
          { type: 'title', text: "Information d'appel" },
          { type: 'shortText', label: "Session d'appel", text: insight_card_contain_text }
        ]
      }
    end

    def insight_card_contain_text
      unavailable = 'Information indisponible'
      parent = Parent.find_by(phone_number: @parent_phone_number)
      group = parent&.current_child&.group
      return unavailable unless group

      "Appel #{group.closest_call_session(Time.zone.today)}"
    end
  end
end
