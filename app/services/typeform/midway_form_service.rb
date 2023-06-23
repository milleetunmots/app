module Typeform
  class MidwayFormService
    FIELD_IDS = {
      mid_term_rate: 'INKahnKw8dxp',
      mid_term_reaction: 'Cya8e9Pyja6e',
      mid_term_speech: 'NTNU28ATjDA4',
    }

    def initialize(form_responses)
      @answers = form_responses[:answers]
      @parent = Parent.find(form_responses[:hidden][:parent_id])
    end

    def call
      @answers.each do |answer|
        case answer[:field][:id]
        when FIELD_IDS[:mid_term_rate]
          @parent.mid_term_rate = answer[:number]
        when FIELD_IDS[:mid_term_reaction]
          @parent.mid_term_reaction = answer[:choice][:label]
        when FIELD_IDS[:mid_term_speech]
          @parent.mid_term_speech = answer[:text]
        end
      end

      @parent.save(validate: false)
      self
    end
  end
end
