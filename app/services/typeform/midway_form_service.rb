module Typeform
  class MidwayFormService < Typeform::TypeformService
    FIELDS = {
      mid_term_rate: ENV['MID_TERM_TYPEFORM_RATE_FIELD'],
      mid_term_reaction: ENV['MID_TERM_TYPEFORM_REACTION_FIELD'],
      mid_term_speech: ENV['MID_TERM_TYPEFORM_SPEECH_FIELD']
    }.freeze

    attr_reader :errors

    def call
      # verify_security_token
      find_parent
      find_child_support
      return self unless @errors.empty?

      @answers.each do |answer|
        case answer[:field][:id]
        when FIELDS[:mid_term_rate]
          @parent.mid_term_rate = answer[:number]
        when FIELDS[:mid_term_reaction]
          @parent.mid_term_reaction = answer[:choice][:label]
        when FIELDS[:mid_term_speech]
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
