module Aircall
  class RetrieveContactService < Aircall::ApiBase

    attr_reader :errors, :contacts

    DEFAULT_PARAMS = '?order=asc&per_page=50'.freeze

    def initialize(endpoint: nil, contact_id: nil)
      # endpoint and contact_id are optional
      # contact_id is used to fetch a single contact
      # endpoint is used if we want to start to fetch contacts with customized params
      if contact_id
        @url = "#{BASE_URL}#{CONTACTS_ENDPOINT}/#{contact_id}"
      else
        @url = endpoint.nil? ? build_url(CONTACTS_ENDPOINT, DEFAULT_PARAMS) : "#{BASE_URL}#{endpoint}"
      end
      @contacts = []
      @errors = []
    end

    def call
      return self unless ENV['AIRCALL_ENABLED']

      # loop through contacts page by page
      loop do
        sleep(1) # basic rate limiting
        response = http_client_with_auth.get(@url)
        if response.status.success?
          body = JSON.parse(response.body)
          @contacts.concat(body['contacts'] || [body['contact']]).uniq!
          next_page = next_page_link(body)
          break if next_page.nil?

          @url = next_page
        else
          @errors << { message: "La récupération de contacts a échoué : #{response.status.reason}", status: response.status.to_i }
          break
        end
      end
      self
    end

  end
end
