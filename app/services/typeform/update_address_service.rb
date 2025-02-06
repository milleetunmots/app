module Typeform
  class UpdateAddressService < Typeform::TypeformService
    FIELD_IDS = {
      address: ENV['ADDRESS_TYPEFORM_ADDRESS_ID'],
      city_name: ENV['ADDRESS_TYPEFORM_CITY_NAME_ID'],
      postal_code: ENV['ADDRESS_TYPEFORM_POSTAL_CODE_ID'],
      letterbox_name: ENV['ADDRESS_TYPEFORM_LETTERBOX_NAME_ID']
    }.freeze


    def call
      verify_hidden_variable('parent_id')
      find_parent
      return self unless @errors.empty?

      @child_support = @parent.current_child&.child_support
      unless @child_support
        @errors << { message: 'ChildSupport not found', parent_id: @parent.id, form_responses: @form_responses }
        return self
      end

      @answers.each do |answer|
        case answer[:field][:id]
        when FIELD_IDS[:address]
          @parent.address = answer[:text]
        when FIELD_IDS[:city_name]
          @parent.city_name = answer[:text]
        when FIELD_IDS[:postal_code]
          @parent.postal_code = answer[:number]
        when FIELD_IDS[:letterbox_name]
          @parent.letterbox_name = answer[:text]
        end
      end

      if @parent.save(validate: false)
        @child_support.address_suspected_invalid_at = nil
        @child_support.save(validate: false)
      end
      self
    end
  end
end
