module Typeform
  class TypeformService

    attr_reader :errors

    def initialize(form_responses)
      @form_responses = form_responses
      @answers = @form_responses[:answers]
      @hidden_variables = @form_responses[:hidden]
      @security_token = @form_responses[:hidden][:st]
      @errors = []
    end

    def verify_security_token
      @errors << { message: 'security token is not present' } if @security_token.blank?
    end

    def find_parent
      @parent = @hidden_variables[:parent_id].present? ? Parent.find_by(id: @hidden_variables[:parent_id]) : Parent.find_by(security_token: @security_token)
      return if @parent.present?

      handle_parent_not_found
    end

    def find_child_support
      if @hidden_variables[:child_support_id].present?
        @child_support = ChildSupport.find_by(id: @hidden_variables[:child_support_id])
      elsif @hidden_variables[:cs].present?
        @child_support = ChildSupport.find_by(id: @hidden_variables[:cs])
      else
        find_parent
        return unless @parent

        current_child = @parent.current_child
        unless current_child
          @errors << { message: 'current child not found', parent_id: @parent.id }
          return
        end
        @child_support = current_child.child_support
      end
      return if @child_support.present?

      handle_child_support_not_found
    end

    def handle_parent_not_found
      error = { message: 'parent not found' }
      error[:parent_id] = @hidden_variables[:parent_id] if @hidden_variables[:parent_id].present?
      error[:security_token] = @security_token if @security_token.present?
      @errors << error
    end

    def handle_child_support_not_found
      error = { message: 'child_support not found' }
      error[:child_support_id] = @hidden_variables[:child_support_id] if @hidden_variables[:child_support_id].present?
      error[:child_support_id] = @hidden_variables[:cs] if @hidden_variables[:cs].present?
      error[:child_id] = @parent.current_child if @parent.current_child.present?
      @errors << error
    end
  end
end
