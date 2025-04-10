module Aircall
  class UpdateContactService < Aircall::ApiBase

    attr_reader :errors, :parent

    def initialize(parent_id:)
      @errors = []
      @parent = Parent.find(parent_id)
      @aircall_id = @parent.aircall_id
      @url = "#{BASE_URL}#{CONTACTS_ENDPOINT}/#{@aircall_id}"
    end

    def call
      return self unless ENV['AIRCALL_ENABLED']

      init_contact_form_data
      verify_contact_form
      return self if @errors.any?

      sleep(1)
      response = http_client_with_auth.post(@url, json: @contact_form)
      if response.status.success?
        @contact = JSON.parse(response)['contact']
        @parent.aircall_id = @contact['id']
        @parent.aircall_datas = @contact
        @parent.save
      else
        @errors << { message: "L'update de contact a échoué : #{response.status.reason}", status: response.status.to_i }
      end
      self
    end

    private

    def init_contact_form_data
      company_name = @parent.children.map(&:first_name).join(', ')
      @errors << { message: "Parent sans enfant principal : #{@parent.id}" } and return unless @parent.current_child&.child_support_id

      information = "#{information}\nCohorte: #{@parent.current_child.group_name}"
      information = "#{information}\nFiche de suivi: #{Rails.application.routes.url_helpers.edit_admin_child_support_url(id: @parent.current_child.child_support_id)}"
      @contact_form = {
        first_name: @parent.first_name,
        last_name: @parent.last_name,
        company_name: company_name,
        information: information
      }
    end

    def verify_contact_form
      if @contact_form.nil?
        @errors << { message: "Impossible d'update le contact : Body params manquant", missing_parameter: 'body_params' }
        return self
      end
      CONTACT_BODY_PARAMS.each do |param|
        next if @contact_form[param].present?

        @errors << { message: "Impossible d'update le contact : Body params manquant", missing_parameter: param.to_s }
        return self
      end
    end
  end
end
