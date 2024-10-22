module Aircall
  class UpdateContactPhoneNumberService

    attr_reader :errors

    def initialize(endpoint: '/v1/contacts', parent:)
      @errors = []
      @endpoint = endpoint
      @parent = parent
      @id = @parent.aircall_id
      @phone_number_id = @parent.aircall_datas['phone_numbers'].first['id']
      @contact_phone_number_form = {
        label: 'Principal',
        value: @parent.phone_number
      }
    end

    def call
      handle_contact_phone_number_form
      return self if @errors.any?

      @aircall_connexion = Aircall::AircallApi.new(endpoint: @endpoint, id: @id, phone_number_id: @phone_number_id)
      sleep(1)
      puts "update phone number #{@aircall_connexion.url}"

      @response = @aircall_connexion.request.put(@aircall_connexion.url, json: @contact_phone_number_form)
      if @response.status.success?
        @phone_detail = JSON.parse(@response)['phone_detail']
        @parent.aircall_datas['phone_numbers'] = [@phone_detail]
        @parent.save
      else
        @errors << { message: "La création a échoué : #{@response.status.reason}", status: @response.status.to_i }
      end
      self
    end

    private

    def handle_contact_phone_number_form
      if @contact_phone_number_form.nil?
        @errors << { message: "Impossible de lancer l'appel api : Body params manquant", missing_parameter: 'body_params' }
        return self
      end
      Aircall::AircallApi::CONTACT_PHONE_NUMBER_BODY_PARAMS.each do |param|
        next if @contact_phone_number_form[param].present?

        @errors << { message: "Impossible de lancer l'appel api : Information liée au numéro de téléphone manquante", missing_parameter: param.to_s }
        return self
      end
    end
  end
end
