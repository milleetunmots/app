module Typeform
  class UpdateAddressService < Typeform::TypeformService
    FIELDS = {
      ENV['UPDATING_ADDRESS_TYPEFORM_ID'] => {
        address: ENV['ADDRESS_TYPEFORM_ADDRESS'],
        address_supplement: ENV['ADDRESS_SUPPLEMENT_TYPEFORM_ADDRESS'],
        city_name: ENV['ADDRESS_TYPEFORM_CITY_NAME'],
        postal_code: ENV['ADDRESS_TYPEFORM_POSTAL_CODE'],
        letterbox_name: ENV['ADDRESS_TYPEFORM_LETTERBOX_NAME']
      },
      ENV['UPSTREAM_ADDRESS_UPDATING_TYPEFORM_ID'] => {
        address: ENV['UPSTREAM_ADDRESS_UPDATING_ADDRESS'],
        address_supplement: ENV['UPSTREAM_ADDRESS_UPDATING_ADDRESS_SUPPLEMENT'],
        city_name: ENV['UPSTREAM_ADDRESS_UPDATING_CITY_NAME'],
        postal_code: ENV['UPSTREAM_ADDRESS_UPDATING_POSTAL_CODE'],
        letterbox_name: ENV['UPSTREAM_ADDRESS_UPDATING_LETTERBOX_NAME']
      },
      ENV['UPDATING_ADDRESS_FOR_PARTNERS_TYPEFORM_ID'] => {
        address: ENV['ADDRESS_FOR_PARTNERS_TYPEFORM_ADDRESS'],
        address_supplement: ENV['ADDRESS_FOR_PARTNERS_SUPPLEMENT_TYPEFORM_ADDRESS'],
        city_name: ENV['ADDRESS_FOR_PARTNERS_TYPEFORM_CITY_NAME'],
        postal_code: ENV['ADDRESS_FOR_PARTNERS_TYPEFORM_POSTAL_CODE'],
        letterbox_name: ENV['ADDRESS_FOR_PARTNERS_TYPEFORM_LETTERBOX_NAME']
      }
    }.freeze

    def initialize(form_responses)
      super(form_responses)
      @form_id = @form_responses[:form_id]
    end

    def call
      # verify_security_token
      find_parent
      return self unless @errors.empty?

      find_child_support
      return self unless @errors.empty?

      @answers.each do |answer|
        case answer[:field][:id]
        when FIELDS[@form_id][:address]
          @parent.address = answer[:text]
        when FIELDS[@form_id][:address_supplement]
          @parent.address_supplement = answer[:text] if answer[:text].present?
        when FIELDS[@form_id][:city_name]
          @parent.city_name = answer[:text]
        when FIELDS[@form_id][:postal_code]
          @parent.postal_code = answer[:number] || answer[:text]
        when FIELDS[@form_id][:letterbox_name]
          @parent.letterbox_name = answer[:text]
        end
      end

      # reset these fields because its not currently updatable via typeform
      @parent.book_delivery_organisation_name = nil
      @parent.book_delivery_location = 'home'
      @parent.geocode
      if @parent.save(validate: false)
        @child_support.address_suspected_invalid_at = nil
        @child_support.save(validate: false)
      end
      self
    end
  end
end
