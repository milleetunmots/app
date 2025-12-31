module Calendly
  class ApiBase

    ORGANIZATION_URI = ENV['CALENDLY_ORGANIZATION_URI']

    BASE_URL = 'https://api.calendly.com'.freeze

    EVENT_TYPES_ENDPOINT = '/event_types'.freeze
    LIST_ORGANIZATION_MEMBERSHIPS_ENDPOINT = '/organization_memberships'.freeze

    protected

    def http_client_with_auth
      HTTP.auth("Bearer #{ENV.fetch('CALENDLY_TOKEN')}")
    end

    def build_url(endpoint, params = '')
      "#{BASE_URL}#{endpoint}#{params}"
    end

    def next_page_link(body)
      pagination = body['pagination']
      return nil unless pagination && pagination['next_page']

      pagination['next_page']
    end
  end
end
