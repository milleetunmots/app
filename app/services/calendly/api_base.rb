module Calendly
  class ApiBase

    BASE_URL = 'https://api.calendly.com'.freeze
    EVENT_TYPES_ENDPOINT = '/event_types'.freeze

    protected

    def http_client_with_auth
      HTTP.auth("Bearer #{ENV.fetch('CALENDLY_TOKEN')}")
    end

    def build_url(endpoint, params = '')
      "#{BASE_URL}#{endpoint}#{params}"
    end
  end
end
