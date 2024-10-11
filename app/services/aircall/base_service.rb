module Aircall
  class BaseService

    BASE_URL = 'https://api.aircall.io'.freeze
    TOKEN_ID = ENV.fetch('AIRCALL_API_ID')
    TOKEN_PASSWORD = ENV.fetch('AIRCALL_API_TOKEN')

    attr_reader :errors, :response

    def initialize(endpoint:, id: nil, phone_number_id: nil, contact_form: nil, phone_number_form: nil)
      @sleep_time = 1
      @id = id
      @phone_number_id = phone_number_id
      @contact_form = contact_form
      @phone_number_form = phone_number_form
      @url = URI("#{BASE_URL}#{endpoint}#{"/#{@id.to_i}#{"/phone_details/#{@phone_number_id.to_i}" if @phone_number_id.present?}" if @id.present?}")
      @response = HTTP.basic_auth(user: TOKEN_ID, pass: TOKEN_PASSWORD)
      @errors = []
    end

    protected

    def handle_post_request
      return if @errors.any?

      sleep(@sleep_time)
      @response = @response.post(@url, json: @contact_form)
      if @response.status.success?
        parse_response
      else
        handle_errors
      end
    end

    def handle_put_request
      return if @errors.any?

      sleep(@sleep_time)
      @response = @response.put(@url, json: @phone_number_form)
      if @response.status.success?
        parse_response
      else
        handle_errors
      end
    end

    def handle_get_request
      sleep(@sleep_time)
      @response = @response.get(@url)
      if @response.status.success?
        parse_response
      else
        handle_errors
      end
    end

    def handle_delete_request
      sleep(@sleep_time)
      @response = @response.delete(@url)
      handle_errors unless @response.status.no_content?
    end

    def parse_response
      @response = JSON.parse(@response.body)
    end

    def handle_errors
      @errors << { message: "L'appel api a échoué : #{@response.status.reason}", status: @response.status.to_i }
      raise StandardError, @response.body if JSON.parse(@response.body)['message'] == 'TooManyRequest'
    end

    def handle_post_request_with_retries
      handle_post_request
    rescue StandardError => e
      raise e unless e.message.include?('TooManyRequest')

      @sleep_time += 1
      handle_post_request
    end

    def handle_put_request_with_retries
      handle_put_request
    rescue StandardError => e
      raise e unless e.message.include?('TooManyRequest')

      @sleep_time += 1
      handle_put_request
    end

    def handle_get_request_with_retries
      handle_get_request
    rescue StandardError => e
      raise e unless e.message.include?('TooManyRequest')

      @sleep_time += 1
      handle_get_request
    end

    def handle_delete_request_with_retries
      handle_delete_request
    rescue StandardError => e
      raise e unless e.message.include?('TooManyRequest')

      @sleep_time += 1
      handle_delete_request
    end

    def handle_form
      @request_body_params.each do |param|
        next if @contact_form[param].present?

        @errors << { message: "Impossible de lancer l'appel api : Body params manquant", missing_parameter: param.to_s }
      end
    end
  end
end
