module Calendly
  class ProcessInviteeCanceledService

    REBOOKING_MESSAGE = <<~MESSAGE.freeze
      1001mots : Bonjour, vous venez d’annuler votre RDV avec {PRENOM_ACCOMPAGNANTE}.
      Vous pouvez choisir un autre créneau pour lui parler ici : {CALENDLY_LINK}
      A bientôt !
    MESSAGE

    attr_reader :errors, :scheduled_call

    def initialize(payload:)
      @errors = []
      @payload = payload
      @invitee_payload = payload['payload'] || payload
    end

    def call
      find_scheduled_call
      return self if @errors.any?

      update_scheduled_call
      return self if @errors.any?

      recreate_one_off_event_type
      return self if @errors.any?

      send_rebooking_message
      self
    end

    private

    def find_scheduled_call
      event_uri = @invitee_payload['event']

      unless event_uri
        @errors << { message: "L'URI de l'événement est manquant dans le payload" }
        return
      end

      @scheduled_call = ScheduledCall.find_by(calendly_event_uri: event_uri)

      return if @scheduled_call

      @errors << {
        message: 'Aucun ScheduledCall trouvé pour cet événement',
        event_uri: event_uri
      }
    end

    def update_scheduled_call
      cancellation = @invitee_payload['cancellation'] || {}
      cancellation_reason = cancellation['reason'] || cancellation['canceler_type']

      canceled_at = if cancellation['canceled_at'].present?
                      Time.zone.parse(cancellation['canceled_at'])
                    else
                      Time.zone.now
                    end

      @scheduled_call.assign_attributes(
        status: 'canceled',
        canceled_at: canceled_at,
        cancellation_reason: cancellation_reason,
        raw_payload: @payload
      )

      return if @scheduled_call.save

      @errors << {
        message: 'Échec de la mise à jour du ScheduledCall',
        validation_errors: @scheduled_call.errors.full_messages
      }
    end

    def recreate_one_off_event_type
      @child_support = @scheduled_call.child_support
      unless @child_support
        @errors << {
          message: 'Le ScheduledCall ne dispose pas de child_support',
          scheduled_call_id: @scheduled_call.id
        }
        return
      end

      @call_session = @scheduled_call.call_session
      unless @call_session
        @errors << {
          message: 'Le ScheduledCall ne dispose pas de call_session',
          scheduled_call_id: @scheduled_call.id
        }
        return
      end

      service = Calendly::CreateOneOffEventTypeService.new(
        child_support: @child_support,
        call_session: @call_session
      ).call
      return if service.errors.empty?

      @errors << {
        message: 'Échec de la création du nouvel one-off event type après annulation',
        errors: service.errors
      }
    end

    def send_rebooking_message
      @parent = @scheduled_call.parent
      unless @parent
        @errors << {
          message: 'Le ScheduledCall ne dispose pas de parent',
          scheduled_call_id: @scheduled_call.id
        }
        return
      end

      calendly_url = @parent.reload.calendly_booking_urls&.dig("call#{@call_session}")
      if calendly_url.blank?
        @errors << {
          message: "Le lien calendly d'une nouvelle prise de rdv n'a pas pu être récupéré",
          parent_id: @parent.id,
          call_session: @call_session
        }
        return
      end

      service = ProgramMessageService.new(
        Time.zone.today.strftime('%d-%m-%Y'),
        Time.zone.now.strftime('%H:%M'),
        ["parent.#{@parent.id}"],
        REBOOKING_MESSAGE.dup.gsub('{CALENDLY_LINK}', calendly_url)
      ).call
      return if service.errors.empty?

      @errors << {
        message: "L'envoi du message de reprise de RDV a échoué",
        errors: service.errors
      }
    end
  end
end
