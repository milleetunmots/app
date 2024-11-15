module Aircall
  class RetrieveUserService < Aircall::ApiBase

    attr_reader :errors, :users

    DEFAULT_PARAMS = '?order=asc&per_page=50'.freeze

    def initialize(endpoint: nil, user_id: nil)
      # endpoint and user_id are optional
      # user_id is used to fetch a single user
      # endpoint is used if we want to start to fetch users with customized params
      if user_id
        @url = "#{BASE_URL}#{USERS_ENDPOINT}/#{user_id}"
      else
        @url = endpoint.nil? ? build_url(USERS_ENDPOINT, DEFAULT_PARAMS) : "#{BASE_URL}#{endpoint}"
      end
      @users = []
      @errors = []
    end

    def call
      # return self unless ENV['AIRCALL_ENABLED']

      # loop through contacts page by page
      loop do
        sleep(1) # basic rate limiting
        response = http_client_with_auth.get(@url)
        if response.status.success?
          body = JSON.parse(response.body)
          @users.concat(body['users'] || [body['user']]).uniq!
          next_page = next_page_link(body)
          break if next_page.nil?

          @url = next_page
        else
          @errors << { message: "La récupération d'utilisateurs a échoué : #{response.status.reason}", status: response.status.to_i }
          break
        end
      end
      self
    end

  end
end
