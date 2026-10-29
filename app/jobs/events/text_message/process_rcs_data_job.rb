class Events::TextMessage

  class ProcessRcsDataJob < ApplicationJob
    queue_as :low

    RCS_STATUS_MAPPING = {
      'QUEUED' => 0,
      'DELIVERED' => 1,
      'SENT' => 2,
      'DELIVERY_RETRIED' => 3,
      'DELIVERY_FAILED' => 4,
      'READ' => 6,
      'SCHEDULE_QUEUED' => 0,
      'SCHEDULED' => 0,
      'SCHEDULE_DELETED' => 4,
      'SCHEDULE_DELETION_FAILED' => 4,
      'CLIENT_MESSAGE_INVALID' => 4,
      'CLIENT_CONFIGURATION_INVALID' => 4,
      'CLIENT_MESSAGE_EXPIRED' => 4,
      'CLIENT_QUOTA_EXCEEDED' => 4,
      'CLIENT_MESSAGE_FORBIDDEN' => 4,
      'CHANNEL_REJECTED' => 4,
      'CHANNEL_UNAVAILABLE' => 4,
      'CHANNEL_INTERNAL_ISSUE' => 4,
      'CHANNEL_OTHER_ISSUE' => 4,
      'USER_UKNOWN' => 4,
      'USER_BLOCKED' => 4,
      'USER_UNAVAILABLE' => 4,
      'INTERNAL_NOT_IMPLEMENTED' => 4,
      'INTERNAL_OTHER_ISSUE' => 4
      }.freeze

    # Erreurs de livraison qui révèlent un problème chez 1001mots ou SpotHit.
    # Les autres (destinataire injoignable, canal indisponible…) font partie de
    # la vie normale d'une campagne : elles ne sont qu'enregistrées dans
    # rcs_error_code.
    ALERTING_RCS_ERROR_CODES = %w[
      CLIENT_MESSAGE_INVALID
      CLIENT_CONFIGURATION_INVALID
      CLIENT_QUOTA_EXCEEDED
      CLIENT_MESSAGE_FORBIDDEN
      INTERNAL_NOT_IMPLEMENTED
      INTERNAL_OTHER_ISSUE
    ].freeze

    def perform(payload)
      Array.wrap(payload['events']).each do |event|
        event_content = event['messageStatusChanged'] || event['userMessageReceived']
        unless event_content
          Rollbar.error('spot_hit_rcs_data: event without content', event: event)
          next
        end

        if event['messageStatusChanged']
          status = event_content['status']
          unless status
            Rollbar.error('spot_hit_rcs_data: RCS status not found', event_content: event_content)
            next
          end

          spot_hit_status = RCS_STATUS_MAPPING[status]
          unless spot_hit_status
            Rollbar.error('spot_hit_rcs_data: unknown rcs status', event_content: event_content)
            next
          end
          next if spot_hit_status.zero?

          text_message_datas = retrieve_text_message_datas(event_content)
          apply_rcs_status_change(event_content, text_message_datas, spot_hit_status)
        elsif event['userMessageReceived']
          unless event['on']
            Rollbar.error('spot_hit_rcs_data: event without date', event: event)
            next
          end

          text_message_datas = retrieve_text_message_datas(event_content)
          event_date = Time.zone.parse(event['on'])
          create_message_received_event(event_date, event_content, text_message_datas)
        else
          Rollbar.error('spot_hit_rcs_data: unknown event', event: event)
        end
      end
    end

    private

    def retrieve_text_message_datas(event_content)
      campaign_id = event_content.dig('context', 'campaign_id')
      unless campaign_id
        Rollbar.error('spot_hit_rcs_data: campaign_id not found', event_content: event_content)
        return {}
      end

      phone = Phonelib.parse(event_content['userId'].to_s.strip).e164
      if phone.blank?
        Rollbar.error('spot_hit_rcs_data: unparsable userId', event_content: event_content)
        return {}
      end

      # Un numéro peut appartenir à plusieurs parents (parents d'une même famille
      # partageant un numéro, familles réinscrites plus tard) : la campagne porte
      # un Event par parent destinataire, tous concernés par ce même message.
      # Volontairement sans `.kept` : un parent supprimé après l'envoi doit tout de
      # même voir le statut de son message évoluer, sans quoi l'Event resterait
      # bloqué en attente.
      parent_ids = Parent.where(phone_number: phone).ids
      if parent_ids.empty?
        Rollbar.error('spot_hit_rcs_data: parent not found', event_content: event_content) if known_campaign?(campaign_id)
        return {}
      end

      # `originated_by_app` exclut les réponses entrantes : elles portent le même
      # `spot_hit_rcs_id` que la campagne, et un callback de statut (READ…) les
      # ferait basculer à « Lu » alors qu'elles viennent du parent, pas de nous.
      text_messages = Events::TextMessage.where(
        spot_hit_rcs_id: campaign_id,
        related_type: 'Parent',
        related_id: parent_ids,
        originated_by_app: true
      ).order(:occurred_at).to_a
      {
        parent: parent_for_received_message(text_messages, parent_ids),
        campaign_id: campaign_id,
        text_messages: text_messages
      }
    end

    # Un message entrant est rattaché en priorité à un parent encore actif, et à
    # celui à qui la campagne a réellement été envoyée.
    # À défaut d'Event de campagne, on retombe sur le parent le plus récemment créé
    # (et non un ordre arbitraire) : c'est celui de la réinscription la plus récente.
    def parent_for_received_message(text_messages, parent_ids)
      parents = text_messages.filter_map(&:related)
      parents.find(&:kept?) || parents.first ||
        Parent.kept.where(id: parent_ids).order(:created_at).last ||
        Parent.where(id: parent_ids).order(:created_at).last
    end

    # Les campagnes envoyées hors de l'app (à la main depuis SpotHit, ou depuis
    # staging et local, qui partagent l'agent de la prod) déclenchent aussi ce
    # webhook : seule une campagne portée par un event sortant de l'app est
    # anormale quand on n'y retrouve pas le destinataire. Les events entrants ne
    # comptent pas, une réponse à une campagne inconnue en crée un.
    def known_campaign?(campaign_id)
      @known_campaigns ||= {}
      return @known_campaigns[campaign_id] if @known_campaigns.key?(campaign_id)

      @known_campaigns[campaign_id] = Events::TextMessage.exists?(spot_hit_rcs_id: campaign_id, originated_by_app: true)
    end

    def apply_rcs_status_change(event_content, text_message_datas, spot_hit_status)
      # Sans données, l'anomalie (campaign_id, userId, parent) a déjà été traitée.
      return if text_message_datas.blank?

      text_messages = text_message_datas[:text_messages]
      if text_messages.blank?
        Rollbar.error('spot_hit_rcs_data: text_message not found for known campaign', event_content: event_content) if known_campaign?(text_message_datas[:campaign_id])
        return
      end

      text_messages.each { |text_message| apply_status_to_text_message(event_content, text_message, spot_hit_status) }
      # Une alerte par événement, même si plusieurs parents partagent le numéro.
      report_delivery_error(event_content)
    end

    def report_delivery_error(event_content)
      return unless event_content['status'] == 'DELIVERY_FAILED'
      return unless ALERTING_RCS_ERROR_CODES.include?(event_content.dig('error', 'code'))

      Rollbar.error('spot_hit_rcs_data: RCS delivery error', event_content: event_content)
    end

    def apply_status_to_text_message(event_content, text_message, spot_hit_status)
      text_message_status = Event::SPOT_HIT_STATUS[text_message.spot_hit_status]
      event_status = Event::SPOT_HIT_STATUS[spot_hit_status]
      retrograde = Event::SPOT_HIT_STATUS_ORDERED.index(text_message_status) > Event::SPOT_HIT_STATUS_ORDERED.index(event_status)
      fallback_after_failure = event_content['channelId'] == 'fallback' && text_message_status == 'Échec'
      # SpotHit ne garantit pas l'ordre chronologique des événements : un statut
      # moins avancé que le statut courant est attendu, on le laisse de côté.
      return if retrograde && !fallback_after_failure

      attributes = { spot_hit_status: spot_hit_status }
      attributes[:is_fallback] = true if event_content['channelId'] == 'fallback'
      attributes[:rcs_error_code] = event_content.dig('error', 'code') if event_content['error']
      Rollbar.error('spot_hit_rcs_data: text_message not updated', event_content: event_content, text_message: text_message) unless text_message.update(attributes)
    end

    def create_message_received_event(date, event_content, text_message_datas)
      parent = text_message_datas[:parent]
      campaign_id = text_message_datas[:campaign_id]
      return if parent.blank? || campaign_id.blank?

      unless event_content['content']
        Rollbar.error('spot_hit_rcs_data: message received content not found', event_content: event_content)
        return
      end

      text = event_content.dig('content', 'text')
      unless text
        Rollbar.error('spot_hit_rcs_data: message received text not found', event_content: event_content)
        return
      end

      text_message = Events::TextMessage.new(
        {
          related: parent,
          body: text,
          spot_hit_rcs_id: campaign_id,
          spot_hit_status: 1,
          occurred_at: date,
          originated_by_app: false
        }
      )
      Rollbar.error('spot_hit_rcs_data: message received text_message not created', event_content: event_content, errors: text_message.errors) unless text_message.save
    end
  end
end
