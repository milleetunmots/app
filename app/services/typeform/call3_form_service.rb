module Typeform
  class Call3FormService
    FIELD_IDS = { call4_previous_goal_follow_up: 'CXDlsCna9dg3' }.freeze

    def initialize(form_responses)
      @answers = form_responses[:answers]
      @child_support = ChildSupport.find(form_responses[:hidden][:child_support_id])
    end

    def call
      @answers.each do |answer|
        next unless answer[:field][:id] == FIELD_IDS[:call4_previous_goal_follow_up]

        @child_support.call4_previous_goals_follow_up = answer[:choice][:label] == 'Oui !' ? '1_succeed' : '3_no_tried'
        @child_support.save
      end
      self
    end
  end
end
