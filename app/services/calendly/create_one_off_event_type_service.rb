module Calendly
  class CreateOneOffEventTypeService < Calendly::ApiBase

    ONE_OFF_EVENT_TYPES_ENDPOINT = '/one_off_event_types'.freeze

    attr_reader :errors

    def initialize(child_support:, call_session:)
      @errors = []
      @child_support = child_support
      @call_session = call_session
      @supporter = child_support&.supporter
      @group = child_support&.current_child&.group
    end

    def call
      handle_errors
      return self if @errors.any?

      create_one_off_event_type_for_parent(@child_support.parent1)
      return self if @errors.any?

      create_one_off_event_type_for_parent(@child_support.parent2)
      self
    end

    private

    def create_one_off_event_type_for_parent(parent)
      return if parent.nil?

      response = http_client_with_auth.post(
        build_url(ONE_OFF_EVENT_TYPES_ENDPOINT),
        json: build_request_body
      )
      sleep(0.25)
      if response.status.success?
        body = JSON.parse(response.body)
        # get scheduling_url or booking_url from response
        @booking_url = extract_booking_url(body)
        @booking_url = add_utm_params(@booking_url, parent) if @booking_url
        parent.calendly_booking_urls["call#{@call_session}"] = @booking_url
        parent.save!
      else
        @errors << {
          message: "La création d'un event type one-off a échoué",
          child_support_id: @child_support.id,
          parent_id: parent.id,
          supporter_id: @supporter.id,
          call_session: @call_session
        }
      end
    end

    def handle_errors
      @errors << "La fiche de suivi n'a pas été trouvée" and return unless @child_support
      @errors << "Pas d'accompagnante sur la fiche de suivi" and return unless @supporter

      @errors << "L'accompagnante n'a pas de calendly_user_uri" unless @supporter.calendly_user_uri.present?
      @errors << "L'accompagnante n'a pas de numéro Aircall" unless @supporter.aircall_phone_number.present?
      @errors << 'Cohorte introuvable' and return unless @group

      @errors << "Les dates de la session d'appel de la cohorte sont manquantes" unless call_dates_present?
    end

    def build_request_body
      {
        name: build_event_name,
        host: @supporter.calendly_user_uri,
        duration: 40,
        date_setting: {
          type: 'date_range',
          start_date: call_start_date.to_s,
          end_date: call_end_date.to_s
        },
        location: {
          kind: 'inbound_call',
          phone_number: @supporter.aircall_phone_number,
          additional_info: "Je vous appellerai sur votre numéro (j'aurai peut-être quelques minutes d'avance ou de retard)"
        },
        locale: 'fr'
      }
    end

    def format_event_name(event_name, child_name)
      event_name.size > 55 ? event_name.gsub(child_name, 'votre enfant') : event_name
    end

    def build_event_name
      child_name = @child_support.current_child.first_name
      case @call_session
      when 0
        format_event_name("Prenons 20 minutes pour discuter de #{child_name} :)", child_name)
      when 1
        format_event_name("20 minutes pour parler de #{child_name} et les livres", child_name)
      when 2
        format_event_name("20 minutes pour aider #{child_name} à bien grandir", child_name)
      when 3
        format_event_name("20 minutes pour parler de ce qui intéresse #{child_name}", child_name)
      end
    end

    def call_start_date
      @group.send("call#{@call_session}_start_date")
    end

    def call_end_date
      @group.send("call#{@call_session}_end_date")
    end

    def call_dates_present?
      call_start_date.present? && call_end_date.present?
    end

    def extract_booking_url(body)
      body.dig('resource', 'booking_url') ||
        body.dig('resource', 'scheduling_url') ||
        body['booking_url'] ||
        body['scheduling_url']
    end

    def add_utm_params(url, parent)
      return nil unless url

      uri = URI.parse(url)
      params = {
        utm_source: '1001mots',
        utm_campaign: "call#{@call_session}",
        utm_content: parent.security_token
      }.compact
      uri.query = URI.encode_www_form(params)
      uri.to_s
    end
  end
end
