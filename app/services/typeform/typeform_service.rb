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
      @errors << { message: "#{variable} is not an integer" } if @hidden_variables[variable.to_sym].to_i.zero?
    end

    def find_parent
      @parent = Parent.find_by(id: @hidden_variables[:parent_id])
      @errors << { message: 'Parent not found', parent_id: @hidden_variables[:parent_id] } unless @parent
    end

    def find_child_support
      @child_support = ChildSupport.find_by(id: @hidden_variables[:child_support_id])
      @errors << { message: 'ChildSupport not found', child_support_id: @hidden_variables[:child_support_id] } unless @child_support
    end

    def verify_security_code
      return if @hidden_variables[:sc].empty?
      return if @parent&.security_code == @hidden_variables[:sc] ||
                @child_support&.parent1&.security_code == @hidden_variables[:sc] ||
                @child_support&.parent2&.security_code == @hidden_variables[:sc]

      @errors << { message: "Security code doesn't match with parent", parent_id: @hidden_variables[:parent_id] }
    end
  end
end
