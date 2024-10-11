module Aircall
  class ContactService < Aircall::BaseService

    POST_REQUEST_BODY_PARAMS = %i[first_name last_name information].freeze
    PHONE_NUMBER_KEYS = %i[label value].freeze

    def initialize(endpoint: '/v1/contacts', id: nil, phone_number_id: nil, contact_form: nil, phone_number_form: nil)
      super
      @request_body_params = POST_REQUEST_BODY_PARAMS
      handle_form if @contact_form
      handle_phone_number_form if @phone_number_form
    end

    def post
      puts @url
      handle_post_request_with_retries
      self
    end

    def put
      puts @url
      handle_put_request_with_retries
      self
    end

    def get
      puts @url
      handle_get_request_with_retries
      self
    end

    def delete
      puts @url
      handle_delete_request_with_retries
      self
    end

    def parse_response
      body = JSON.parse(@response.body)
      meta = body['meta']
      @response = body['contacts'] || body['contact'] || body['phone_detail']

      if meta && meta['next_page_link']
        next_endpoint = meta['next_page_link'].split('api.aircall.io').second
        next_response = Aircall::ContactService.new(endpoint: next_endpoint).get.response
        @response.concat(next_response).uniq!
      end
    end

    def handle_form
      super
      return if @id

      PHONE_NUMBER_KEYS.each do |key|
        next if @contact_form[:phone_numbers].first[key].present?

        @errors << { message: "Impossible de lancer l'appel api : Information liée au numéro de téléphone manquante", missing_parameter: key.to_s }
      end
    end

    def handle_phone_number_form
      PHONE_NUMBER_KEYS.each do |param|
        next if @phone_number_form[param].present?

        @errors << { message: "Impossible de lancer l'appel api : Information liée au numéro de téléphone manquante", missing_parameter: param.to_s }
      end
    end
  end
end
