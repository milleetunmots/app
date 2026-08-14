module Calendly
  class RetrieveOrganizationMembershipsService < Calendly::ApiBase

    attr_reader :errors, :users

    def initialize
      @url = build_url(LIST_ORGANIZATION_MEMBERSHIPS_ENDPOINT)
      @errors = []
      @users = []
    end

    def call
      loop do
        sleep(1)
        response = http_client_with_auth.get(
          @url,
          params: {
            organization: ORGANIZATION_URI
          }
        )
        body = parse_json_response(response)
        if body.is_a?(Hash) && body['collection'].is_a?(Array)
          @users.concat(body['collection'].map { |membership| membership['user']}).uniq!
          next_page = next_page_link(body)
          break if next_page.nil?

          @url = next_page
        else
          @errors << { message: "La récupération des utilisateurs a échoué : #{response.status.reason}", status: response.status.to_i }
          break
        end
      end
      self
    end
  end
end
