module Aircall
  class CreateInsightCardService < Aircall::ApiBase

    attr_reader :errors

    def initialize(payload:)
      @errors = []
      @call_id = payload['id']
      @parent_phone_number = Phonelib.parse(payload['raw_digits']).e164
      @parent = Parent.find_by(phone_number: @parent_phone_number)
    end

    protected

    def perform_resquest
      response = http_client_with_auth.post(build_url(CALLS_ENDPOINT, "/#{@call_id}/insight_cards"), json: insight_card_contain)
      @errors << { message: "La création de l'aperçu d'appel a échoué : #{response.status.reason}", status: response.status.to_i, parent_phone_number: @parent_phone_number } unless response.status.success?
    end

    def insight_card_contain
      { contents: [
        { type: 'title', text: @insight_card_title },
        { type: 'shortText', label: @insight_card_label, text: @insight_card_contain_text }
      ] }
    end
  end
end
