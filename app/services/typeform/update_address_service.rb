module Typeform
  class UpdateAddressService < Typeform::TypeformService
    FIELD_IDS = {
      ENV['UPDATING_ADDRESS_TYPEFORM_ID'] => {
        address: ENV['ADDRESS_TYPEFORM_ADDRESS_ID'],
        city_name: ENV['ADDRESS_TYPEFORM_CITY_NAME_ID'],
        postal_code: ENV['ADDRESS_TYPEFORM_POSTAL_CODE_ID'],
        letterbox_name: ENV['ADDRESS_TYPEFORM_LETTERBOX_NAME_ID']
      },
      ENV['UPSTREAM_ADDRESS_UPDATING_TYPEFORM_ID'] => {
        address: ENV['UPSTREAM_ADDRESS_UPDATING_ADDRESS_ID'],
        city_name: ENV['UPSTREAM_ADDRESS_UPDATING_CITY_NAME_ID'],
        postal_code: ENV['UPSTREAM_ADDRESS_UPDATING_POSTAL_CODE_ID'],
        letterbox_name: ENV['UPSTREAM_ADDRESS_UPDATING_LETTERBOX_NAME_ID']
      }
    }.freeze

    def initialize(form_responses)
      super(form_responses)
      @form_id = @form_responses[:form_id]
    end

    def call
      verify_hidden_variable('parent_id')
      find_parent
      return self unless @errors.empty?

      verify_security_code
      return self unless @errors.empty?

      @child_support = @parent.current_child&.child_support
      unless @child_support
        @errors << { message: 'ChildSupport not found', parent_id: @parent.id }
        return self
      end

      @answers.each do |answer|
        case answer[:field][:id]
        when FIELD_IDS[@form_id][:address]
          @parent.address = answer[:text]
        when FIELD_IDS[@form_id][:city_name]
          @parent.city_name = answer[:text]
        when FIELD_IDS[@form_id][:postal_code]
          @parent.postal_code = answer[:number]
        when FIELD_IDS[@form_id][:letterbox_name]
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
