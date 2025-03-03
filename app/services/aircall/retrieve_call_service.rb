module Aircall
  class RetrieveCallService < Aircall::ApiBase

    attr_reader :errors, :calls

    DEFAULT_PARAMS = '?order=asc&per_page=50'.freeze

    def initialize(endpoint: nil, call_id: nil)
      # endpoint and call_id are optional
      # call_id is used to fetch a single call
      # endpoint is used if we want to start to fetch calls with customized params
      if call_id
        @url = "#{BASE_URL}#{CALLS_ENDPOINT}/#{call_id}"
      else
        @url = endpoint.nil? ? build_url(CALLS_ENDPOINT, DEFAULT_PARAMS) : "#{BASE_URL}#{endpoint}"
      end
      @calls = []
      @errors = []
    end

    def call
      return self unless ENV['AIRCALL_ENABLED']

      # loop through calls page by page
      loop do
        sleep(1) # basic rate limiting
        response = http_client_with_auth.get(@url)
        if response.status.success?
          body = JSON.parse(response.body)
          @calls.concat(body['calls'] || [body['call']]).uniq!
          next_page = next_page_link(body)
          break if next_page.nil?

          @url = next_page
        else
          @errors << { message: "La récupération de appels a échoué : #{response.status.reason}", status: response.status.to_i }
          break
        end
      end
      self
    end

  end
end
