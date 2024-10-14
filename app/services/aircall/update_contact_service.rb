module Aircall
  class UpdateContactService < Aircall::ApiBase

    attr_reader :errors

    def initialize(endpoint: '/v1/contacts', parent:)
      @errors = []
      @endpoint = endpoint
      @parent = parent
      @id = @parent.aircall_id
      information = "Enfant(s):\n#{@parent.children.decorate.map(&:name).join(', ')}"
      information = "#{information}\nFiche de suivi: #{Rails.application.routes.url_helpers.admin_child_support_url(id: @parent.current_child.child_support_id)}"
      information = "#{information}\nEnfant principal: #{Rails.application.routes.url_helpers.admin_child_url(id: @parent.current_child.id)}"
      @contact_form = {
        first_name: @parent.first_name,
        last_name: @parent.last_name,
        information: information,
        phone_numbers: [
          {
            label: 'Principal',
            value: @parent.phone_number
          }
        ]
      }
    end

    def call
      handle_contact_form
      return self if @errors.any?

      @aircall_connexion = Aircall::ApiBase.new(endpoint: @endpoint, id: @id)
      sleep(1)
      puts "update contact #{@aircall_connexion.url}"

      @response = @aircall_connexion.request.post(@aircall_connexion.url, json: @contact_form)
      if @response.status.success?
        @contact = JSON.parse(@response)['contact']
        @parent.aircall_id = @contact['id']
        @parent.aircall_datas = @contact
        @parent.save
      else
        @errors << { message: "La création a échoué : #{@response.status.reason}", status: @response.status.to_i }
      end
      self
    end

    private

    def handle_contact_form
      if @contact_form.nil?
        @errors << { message: "Impossible de lancer l'appel api : Body params manquant", missing_parameter: 'body_params' }
        return self
      end
      if @contact_form[:phone_numbers].nil?
        @errors << { message: "Impossible de lancer l'appel api : Body params manquant", missing_parameter: 'phone_numbers' }
        return self
      end
      Aircall::ApiBase::CONTACT_BODY_PARAMS.each do |param|
        next if @contact_form[param].present?

        @errors << { message: "Impossible de lancer l'appel api : Body params manquant", missing_parameter: param.to_s }
        return self
      end
      Aircall::ApiBase::CONTACT_PHONE_NUMBER_BODY_PARAMS.each do |param|
        next if @contact_form[:phone_numbers].first[param].present?

        @errors << { message: "Impossible de lancer l'appel api : Information liée au numéro de téléphone manquante", missing_parameter: param.to_s }
        return self
      end
    end
  end
end
