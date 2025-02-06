module Typeform
  class TypeformService

    attr_reader :errors

    def initialize(form_responses)
      @form_responses = form_responses
      @answers = @form_responses[:answers]
      @hidden_variables = @form_responses[:hidden]
      @errors = []
    end

    def verify_hidden_variable(variable)
      @errors << { message: "#{variable} is not an integer", form_responses: @form_responses } if @hidden_variables[variable.to_sym].to_i.zero?
    end

    def find_parent
      @parent = Parent.find_by(id: @hidden_variables[:parent_id])
      @errors << { message: 'Parent not found', parent_id: @hidden_variables[:parent_id], form_responses: @form_responses } unless @parent
    end

    def find_child_support
      @child_support = ChildSupport.find_by(id: @hidden_variables[:child_support_id])
      @errors << { message: 'ChildSupport not found', child_support_id: @hidden_variables[:child_support_id], form_responses: @form_responses } unless @child_support
    end
  end
end
