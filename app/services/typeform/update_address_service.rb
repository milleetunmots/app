module Typeform
  class UpdateAddressService
    FIELD_IDS = {
      address: 'buGg1ITHz89C'

    }

    def initialize(form_responses)
      @answers = form_responses[:answers]
      @parent = Parent.find(form_responses[:hidden][:parent_id])
      @child_support = @parent.current_child&.child_support
    end

    def call
      unless @child_support
        Rollbar('Typeform::UpdateAddressService', parent: @parent.id, child_support: @child_support)
        return self
      end

      @answers.each do |answer|
        # case answer[:field][:id]
        # when FIELD_IDS[:mid_term_rate]
        #   @parent.mid_term_rate = answer[:number]
        # when FIELD_IDS[:mid_term_reaction]
        #   @parent.mid_term_reaction = answer[:choice][:label]
        # when FIELD_IDS[:mid_term_speech]
        #   @parent.mid_term_speech = answer[:text]
        # end
      end

      # if @parent.save(validate: false)
      #   @child_support.parent_mid_term_rate = @parent.reload.mid_term_rate if should_update_mid_term_info?(:parent_mid_term_rate)
      #   @child_support.parent_mid_term_reaction = @parent.reload.mid_term_reaction if should_update_mid_term_info?(:parent_mid_term_reaction)
      #   @child_support.save(validate: false)
      # end
      self
    end

    private

  end
end
