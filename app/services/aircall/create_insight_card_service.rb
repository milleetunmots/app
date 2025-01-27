module Aircall
  class CreateInsightCardService < Aircall::ApiBase

    attr_reader :errors

    def initialize(call_id:, parent_phone_number:)
      @errors = []
      @call_id = call_id
      @parent_phone_number = parent_phone_number
    end

    def call
      response = http_client_with_auth.post(build_url(CALLS_ENDPOINT, "/#{@call_id}/insight_cards"), json: insight_card_contain)
      unless response.status.success?
        @errors << { message: "La création de l'aperçu d'appel a échoué : #{response.status.reason}", status: response.status.to_i, parent_phone_number: @parent_phone_number }
      end
      self
    end

    private

    def insight_card_contain
      { contents: [{ type: 'shortText', text: insight_card_contain_text }] }
    end

    def insight_card_contain_text
      parent = Parent.find_by(phone_number: @parent_phone_number)
      return 'Ce parent est introuvable' unless parent

      current_child = parent.current_child
      return "Ce parent n'a pas d'enfant principal" unless current_child

      group = current_child.group
      return "L'enfant principal de ce parent n'a pas de cohorte" unless group

      "Cet appel entrant est un appel #{group.closest_call_session(Time.zone.today)}"
    end
  end
end
