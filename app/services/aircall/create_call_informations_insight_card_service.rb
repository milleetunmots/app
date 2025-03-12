module Aircall
  class CreateCallInformationsInsightCardService < Aircall::CreateInsightCardService

    attr_reader :errors

    def initialize(payload:)
      super(payload: payload)
      @inbound = payload['direction'] == 'inbound'
      @insight_card_label = "Session d'appel"
      @insight_card_title = "Information d'appel"
      @insight_card_contain_text =
        if @parent&.current_child&.group
          "Appel #{@parent&.current_child&.group&.closest_call_session(Time.zone.today)}"
        else
          'Information indisponible'
        end
    end

    def call
      return self unless @inbound && @parent

      perform_resquest
      self
    end
  end
end
