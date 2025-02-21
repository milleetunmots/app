module Typeform
  class MidwayFormService < Typeform::TypeformService
    FIELD_IDS = {
      mid_term_rate: ENV['MID_TERM_TYPEFORM_RATE_ID'],
      mid_term_reaction: ENV['MID_TERM_TYPEFORM_REACTION_ID'],
      mid_term_speech: ENV['MID_TERM_TYPEFORM_SPEECH_ID']
    }.freeze

    attr_reader :errors

    def call
      verify_hidden_variables('child_support_id')
      verify_hidden_variables('parent_id')
      find_child_support
      find_parent
      return self unless @errors.empty?

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
        @errors << { message: 'ChildSupport saving failed', child_support_id: @child_support.id } unless @child_support.save(validate: false)
      else
        @errors << { message: 'Parent saving failed', parent_id: @parent.id }
      end
      self
    end

    private

    def should_update_mid_term_info?(mid_term_attribute)
      (@parent == @child_support.parent1) || @child_support.send(mid_term_attribute).blank?
    end
  end
end
