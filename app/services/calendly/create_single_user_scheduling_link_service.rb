module Calendly
  class CreateSingleUserSchedulingLinkService < Calendly::ApiBase

    attr_reader :errors, :booking_url

    def initialize(admin_user_id:, child_support_id:, call_session:)
      @errors = []
      @admin_user = AdminUser.find_by(id: admin_user_id)
      @child_support = ChildSupport.find_by(id: child_support_id)
      @call_session = call_session
    end

    def call
      unless @admin_user
        @errors << { message: "L'utilisateur n'a pas été trouvé" }
        return self
      end
      unless @child_support
        @errors << { message: "La fiche de suivi n'a pas été trouvé" }
        return self
      end
      event_type_uri = @admin_user.calendly_event_type_uris&.dig("call#{@call_session}")
      unless event_type_uri
        @errors << {
          message: "L'event type pour l'appel #{@call_session} n'a pas été trouvé",
          admin_user_id: @admin_user.id,
          call_session: @call_session
        }
        return self
      end
      response = http_client_with_auth.post(
        build_url(SINGLE_USE_SCHEDULING_LINK_ENDPOINT),
        json: build_request_body(event_type_uri)
      )
      handle_scheduling_link_response(response)
      self
    end

    private

    def handle_scheduling_link_response(response)
      body = parse_json_body(response) || {}
      resource = body['resource']

      if response.status.success? && resource.is_a?(Hash) && resource['booking_url'].present?
        @booking_url = add_utm_params(resource['booking_url'])
      else
        @errors << {
          message: 'La création du lien à usage unique a échoué',
          details: body['details'] || response.body.to_s.truncate(500),
          child_support_id: @child_support.id,
          admin_user_id: @admin_user.id
        }
      end
    end

    def build_request_body(event_type_uri)
      {
        max_event_count: 1,
        owner: event_type_uri,
        owner_type: 'EventType'
      }
    end

    def add_utm_params(url)
      uri = URI.parse(url)
      params = {
        utm_source: '1001mots',
        utm_campaign: "call#{@call_session}",
        utm_content: @child_support.parent1&.security_token
      }.compact
      uri.query = URI.encode_www_form(params)
      uri.to_s
    end
  end
end
