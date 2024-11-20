module Typeform
  class UpdateAddressService
    FIELD_IDS = {
      address: 'buGg1ITHz89C',
      city_name: 'UfJYnoBckGEV',
      postal_code: 'qG2FxwtkolB8',
      letterbox_name: 'KYLiAIq8idLb'
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
        case answer[:field][:id]
        when FIELD_IDS[:address]
          @parent.address = answer[:text]
        when FIELD_IDS[:city_name]
          @parent.city_name = answer[:text]
        when FIELD_IDS[:postal_code]
          @parent.postal_code = answer[:text]
        when FIELD_IDS[:letterbox_name]
          @parent.letterbox_name = answer[:text]
        end
      end

      if @parent.save(validate: false)
        @child_support.is_address_suspected_invalid = false
        @child_support.save(validate: false)
      end
      self
    end
  end
end
