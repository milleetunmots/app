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
      @errors << { message: 'security token is not present' } if @security_token.nil?
    end

    def find_parent
      @parent = @hidden_variables[:parent_id].present? ? Parent.find_by(id: @hidden_variables[:parent_id]) : Parent.find_by(security_token: @security_token)
      return if @parent.present?

      if @hidden_variables[:parent_id].present?
        @errors << { message: 'parent not found', parent_id: @hidden_variables[:parent_id] }
      else
        @errors << { message: 'parent not found', security_token: @security_token }
      end
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

      if @hidden_variables[:child_support_id].present?
        @errors << { message: 'childSupport not found', child_support_id: @hidden_variables[:child_support_id] }
      elsif @hidden_variables[:cs].present?
        @errors << { message: 'child support not found', child_support_id: @hidden_variables[:cs] }
      else
        @errors << { message: 'child support not found', child_id: current_child.id } unless @child_support
      end
    end
  end
end
