module Typeform
  class CallGoalsFormService
    FIELD_IDS = %w[CXDlsCna9dg3 lwth2Bv3Pzqm tgVue9vTFuJK].freeze

    def initialize(form_responses, call_index)
      @answers = form_responses[:answers]
      @call_index = call_index
      @child_support = ChildSupport.find(form_responses[:hidden][:child_support_id])
    end

    def call
      @answers.each do |answer|
        next unless answer[:field][:id].in? FIELD_IDS

        call_previous_goals_follow_up = answer[:choice][:label] == 'Oui !' ? '1_succeed' : '3_no_tried'
        @child_support.assign_attributes("call#{@call_index + 1}_previous_goals_follow_up": call_previous_goals_follow_up)
        @child_support.save
      end
      self
    end
  end
end
