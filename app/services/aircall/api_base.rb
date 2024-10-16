module Aircall
  class ApiBase

    BASE_URL = 'https://api.aircall.io'.freeze
    CONTACTS_ENDPOINT = '/v1/contacts'.freeze

    TOKEN_ID = ENV.fetch('AIRCALL_API_ID')
    TOKEN_PASSWORD = ENV.fetch('AIRCALL_API_TOKEN')

    CONTACT_BODY_PARAMS = %i[first_name last_name information].freeze
    CONTACT_PHONE_NUMBER_BODY_PARAMS = %i[label value].freeze

    protected

    def http_client_with_auth
      HTTP.basic_auth(user: TOKEN_ID, pass: TOKEN_PASSWORD)
    end

    def build_url(endpoint, params = '')
      "#{BASE_URL}#{endpoint}#{params}"
    end

    def next_page_link(body)
      meta = body['meta']
      return nil unless meta && meta['next_page_link']

      next_link = meta['next_page_link']
      
      # prefix with BASE_URL if link is relative
      next_link.start_with?('http') ? next_link : "#{BASE_URL}#{next_link.split('api.aircall.io').last}"
    end
  end
end
