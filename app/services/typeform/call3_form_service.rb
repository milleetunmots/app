module Typeform
  class Call3FormService
    FIELD_IDS = %w[CXDlsCna9dg3 lwth2Bv3Pzqm].freeze

    def initialize(form_responses)
      @answers = form_responses[:answers]
      @child_support = ChildSupport.find(form_responses[:hidden][:child_support_id])
    end

    def call
      @answers.each do |answer|
        next unless answer[:field][:id].in? FIELD_IDS

        @child_support.call4_previous_goals_follow_up = answer[:choice][:label] == 'Oui !' ? '1_succeed' : '3_no_tried'
        @child_support.save
      end
      self
    end
  end
end
