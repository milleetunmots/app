module Typeform
  class CallGoalsFormService < Typeform::TypeformService

    FIELDS = ENV['CALL_ZERO_TYPEFORM_FIELDS'].split(', ')

    def initialize(form_responses, call_index)
      super(form_responses)
      @call_index = call_index
    end

    def call
      # verify_security_token
      find_child_support
      return self unless @errors.empty?

      @answers.each do |answer|
        next unless answer[:field][:id].in? FIELDS

        call_previous_goals_follow_up = answer[:choice][:label] == 'Oui !' ? '1_succeed' : '3_no_tried'
        @child_support.assign_attributes("call#{@call_index + 1}_previous_goals_follow_up": call_previous_goals_follow_up)
        @errors << { message: 'ChildSupport saving failed', child_support_id: @child_support.id } unless @child_support.save
      end
      self
    end
  end
end
