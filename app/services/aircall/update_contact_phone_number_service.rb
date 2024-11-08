module Aircall
  class UpdateContactPhoneNumberService < Aircall::ApiBase

    attr_reader :errors, :parent

    def initialize(parent_id:)
      @errors = []
      @parent = Parent.find(parent_id)
      @aircall_id = @parent.aircall_id
      @phone_number_id = @parent.aircall_datas['phone_numbers'].first['id']
      @url = "#{BASE_URL}#{CONTACTS_ENDPOINT}/#{@aircall_id}/phone_details/#{@phone_number_id}"
      @contact_phone_number_form = {
        label: 'Principal',
        value: @parent.phone_number
      }
    end

    def call
      return self unless ENV['AIRCALL_ENABLED']

      verify_contact_phone_number_form
      return self if @errors.any?

      sleep(1)
      response = http_client_with_auth.put(@url, json: @contact_phone_number_form)
      if response.status.success?
        @phone_detail = JSON.parse(response)['phone_detail']
        @parent.aircall_datas['phone_numbers'] = [@phone_detail]
        @parent.save
      else
        @errors << { message: "L'update du numéro de téléphone a échoué : #{response.status.reason}", status: response.status.to_i }
      end
      self
    end

    private

    def verify_contact_phone_number_form
      if @contact_phone_number_form.nil?
        @errors << { message: "Impossible de modifier le numéro de téléphone : Body params manquant", missing_parameter: 'body_params' }
        return self
      end
      CONTACT_PHONE_NUMBER_BODY_PARAMS.each do |param|
        next if @contact_phone_number_form[param].present?

        @errors << { message: "Impossible de modifier le numéro de téléphone : Information liée au numéro de téléphone manquante", missing_parameter: param.to_s }
        return self
      end
    end
  end
end
