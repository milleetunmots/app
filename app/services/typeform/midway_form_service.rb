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
      @child_support = ChildSupport.find(form_responses[:hidden][:child_support_id])
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

      if @parent.save(validate: false)
        @child_support.parent_mid_term_rate = @parent.reload.mid_term_rate if should_update_mid_term_info?(:parent_mid_term_rate)
        @child_support.parent_mid_term_reaction = @parent.reload.mid_term_reaction if should_update_mid_term_info?(:parent_mid_term_reaction)
        @child_support.save(validate: false)
      end
      self
    end

    private

    def should_update_mid_term_info?(mid_term_attribute)
      (@parent == @child_support.parent1) || @child_support.send(mid_term_attribute).blank?
    end
  end
end
