module Typeform
  class UpdateAddressService
    FIELD_IDS = {
      address: 'N8yUG2jdg0QT',
      city_name: 'lh7ySr1ry9mP',
      postal_code: 'xq3aifkWgIYY',
      letterbox_name: 'B7xao8q1J483'
    }

    def initialize(form_responses)
      @answers = form_responses[:answers]
      @parent = Parent.find_by(id: form_responses[:hidden][:parent_id])
    end

    def call
      unless @parent
        Rollbar.error('Typeform::UpdateAddressService', parent: @parent)
        return self
      end

      @child_support = @parent.current_child&.child_support
      unless @child_support
        Rollbar.error('Typeform::UpdateAddressService', parent: @parent.id, child_support: @child_support)
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
