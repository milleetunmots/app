module Aircall
  class CreateCallRecordingInsightCardService < Aircall::CreateInsightCardService

    attr_reader :errors

    def initialize(payload:)
      super(payload: payload)
      @insight_card_title = "Enregistrement d'appel"
      @insight_card_label = 'Enregistrement'
      @insight_card_contain_text = 'Recommandé'
    end

    def call
      return self unless @parent&.current_child&.group_enable_calls_recording

      perform_resquest
      self
    end
  end
end
