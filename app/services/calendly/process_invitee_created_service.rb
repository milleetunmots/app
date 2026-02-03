module Calendly
  class ProcessInviteeCreatedService

    attr_reader :errors, :scheduled_call

    def initialize(payload:)
      @errors = []
      @payload = payload
      @invitee_payload = payload['payload'] || payload
    end

    def call
      extract_tracking_info
      return self if @errors.any?

      find_parent
      return self if @errors.any?

      find_child_support
      fetch_event_details
      find_admin_user
      extract_invitee_comment

      create_or_update_scheduled_call
      self
    end

    private

    def extract_tracking_info
      tracking = @invitee_payload['tracking'] || {}
      @security_token = tracking['utm_content']
      @utm_campaign = tracking['utm_campaign']
      @call_session = extract_call_session(@utm_campaign)

      return if @security_token.present?

      @errors << {
        message: 'Le security_token (utm_content) est manquant dans le payload',
        tracking: tracking
      }
    end

    def extract_call_session(utm_campaign)
      return nil if utm_campaign.blank?

      match = utm_campaign.match(/call(\d+)/)
      match[1].to_i if match
    end

    def find_parent
      @parent = Parent.find_by(security_token: @security_token)

      return if @parent

      @errors << {
        message: 'Aucun parent trouvé avec le security_token',
        security_token: @security_token
      }
    end

    def find_child_support
      return unless @parent

      @child_support = @parent.current_child&.child_support

      return if @child_support

      @errors << {
        message: 'Aucune fiche de suivi trouvée pour ce parent',
        parent_id: @parent.id
      }
    end

    def find_admin_user
      @event_type_uri = @event_data&.dig(:event_type_uri)

      if @event_type_uri
        @admin_user = AdminUser.find_by(
          'calendly_event_type_uris @> ?',
          { "call#{@call_session}" => @event_type_uri }.to_json
        )
        @admin_user ||= find_admin_user_by_event_type_uri(@event_type_uri)
      end

      @admin_user ||= @child_support&.supporter
    end

    def find_admin_user_by_event_type_uri(event_type_uri)
      AdminUser.where.not(calendly_event_type_uris: nil).find do |admin_user|
        admin_user.calendly_event_type_uris&.value?(event_type_uri)
      end
    end

    def fetch_event_details
      event_uri = @invitee_payload['event']
      return unless event_uri

      fetch_service = Calendly::FetchScheduledEventService.new(event_uri: event_uri).call

      if fetch_service.errors.any?
        @errors.concat(fetch_service.errors)
        return
      end

      @event_data = fetch_service.event_data
    end

    def extract_invitee_comment
      questions_and_answers = @invitee_payload['questions_and_answers'] || []
      return if questions_and_answers.empty?

      @invitee_comment = questions_and_answers.map do |qa|
        "#{qa['question']}: #{qa['answer']}"
      end.join("\n")
    end

    def create_or_update_scheduled_call
      event_uri = @invitee_payload['event']

      @scheduled_call = ScheduledCall.find_or_initialize_by(calendly_event_uri: event_uri)

      @scheduled_call.assign_attributes(
        calendly_invitee_uri: @invitee_payload['uri'],
        admin_user: @admin_user,
        child_support: @child_support,
        parent: @parent,
        call_session: @call_session,
        scheduled_at: @event_data&.dig(:start_time),
        duration_minutes: @event_data&.dig(:duration_minutes),
        event_type_name: @event_data&.dig(:event_type_name),
        event_type_uri: @event_type_uri,
        invitee_email: @invitee_payload['email'],
        invitee_name: @invitee_payload['name'],
        invitee_comment: @invitee_comment,
        status: 'scheduled',
        raw_payload: @payload
      )

      return if @scheduled_call.save

      @errors << {
        message: 'Échec de la sauvegarde du ScheduledCall',
        validation_errors: @scheduled_call.errors.full_messages
      }
    end
  end
end
