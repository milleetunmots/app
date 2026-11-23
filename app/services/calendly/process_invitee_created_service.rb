module Calendly
  class ProcessInviteeCreatedService

    CONFIRMATION_BUNDLE = ['Confirmation de RDV', 'confirmation_rdv'].freeze

    REPLACED_CANCELLATION_REASON = 'Remplacé par un nouveau RDV'.freeze

    attr_reader :errors, :scheduled_call

    def initialize(payload:)
      @errors = []
      @payload = payload
      @invitee_payload = payload['payload'] || payload
    end

    def call
      identify_parent
      return self if @errors.any?

      find_child_support
      fetch_event_details
      extract_event_type_uri

      find_admin_user
      extract_invitee_comment

      create_or_update_scheduled_call
      return self if @errors.any?

      # webhook dupliqué (retry Calendly) : l'événement a déjà été traité,
      # on ne déclenche ni remplacement ni renvoi de confirmation
      return self if @already_processed

      cancel_replaced_scheduled_calls
      send_scheduled_call_confirmation
      self
    end

    private

    def identify_parent
      service = Parent::IdentifyCalendlyInviteeService.new(invitee_payload: @invitee_payload).call
      @errors.concat(service.errors)
      @parent = service.parent
      @call_session = service.call_session
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
      @admin_user = @child_support&.supporter
    end

    def extract_event_type_uri
      @event_type_uri = @invitee_payload.dig('scheduled_event', 'event_type') || @event_data&.dig(:event_type_uri)
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
      @already_processed = @scheduled_call.persisted? && @scheduled_call.scheduled?

      @scheduled_call.assign_attributes(
        cancel_url: @invitee_payload['cancel_url'],
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

    # un seul RDV actif par fiche de suivi et par session : le nouveau RDV
    # remplace les précédents, annulés sur Calendly puis localement
    def cancel_replaced_scheduled_calls
      return unless @child_support && @call_session && @parent

      ScheduledCall.scheduled
                   .upcoming
                   .where(child_support: @child_support, call_session: @call_session, parent: @parent)
                   .where.not(id: @scheduled_call.id)
                   .find_each do |replaced_call|
        cancel_service = Calendly::CancelScheduledEventService.new(
          event_uri: replaced_call.calendly_event_uri,
          reason: REPLACED_CANCELLATION_REASON
        ).call

        # si Calendly a refusé l'annulation, le créneau y est toujours réservé :
        # le laisser « scheduled » localement reste l'état le plus fidèle
        if cancel_service.errors.any?
          @errors << {
            message: "L'annulation sur Calendly du RDV remplacé a échoué",
            scheduled_call_id: replaced_call.id,
            errors: cancel_service.errors
          }
          next
        end

        replaced_call.cancel!(reason: REPLACED_CANCELLATION_REASON)
      end
    end

    def send_scheduled_call_confirmation
      name, key = CONFIRMATION_BUNDLE
      bundle = Media::TextMessagesBundle.find_automatic(name: name, key: key)
      return @errors << { message: Media::TextMessagesBundle.missing_message(name: name, key: key) } unless bundle

      service = ProgramAutomaticMessageService.new(
        Time.zone.now.strftime('%d-%m-%Y'), Time.zone.now.strftime('%H:%M'), ["parent.#{@parent.id}"],
        bundle.body1, bundle.rcs_media_id_to_send(1), bundle.redirection_target_id(1),
        automatic_message_key: key, recipient_variables: { @parent.id => scheduled_call_variables }
      ).call
      return if service.errors.empty?

      @errors << { message: "Échec de l'envoi du message de confirmation de RDV", errors: service.errors }
    end

    # Le RDV qui vient d'être pris, pas le dernier RDV à venir que retiendrait ProgramMessageService.
    def scheduled_call_variables
      {
        'SCHEDULED_AT_DATE' => @scheduled_call.scheduled_at.strftime('%d/%m'),
        'RDV_CALENDLY_SCHEDULED_AT_HOUR' => @scheduled_call.scheduled_at.strftime('%H:%M'),
        'RDV_CALENDLY_CANCEL_URL' => @scheduled_call.cancel_url.to_s
      }
    end
  end
end
