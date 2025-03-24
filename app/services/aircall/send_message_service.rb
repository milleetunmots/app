module Aircall
  class SendMessageService < Aircall::ApiBase
    attr_reader :errors, :event_id

    def initialize(number_id:, to:, body:, event_id:)
      @errors = []
      @number_id = number_id
      @to = to
      @body = body
      @event_id = event_id
    end

    def call
      return self unless ENV['AIRCALL_ENABLED']
      @event = Event.find_by(id: @event_id)
      if @to.blank? || @number_id.blank?
        @errors << "Envoi impossible à cause de paramètres invalides"
        update_event(4)
        return self
      end
      

      if Rails.env.development? || ENV['SPOT_HIT_SAFEGUARD'].present?
        safe_numbers = ENV['SAFE_PHONE_NUMBERS'].to_s.split(',').map(&:strip)
        unless safe_numbers.include?(@to)
          @errors << "Numéro invalide : il n'est pas whitelisté"
          update_event(4)
          return self
        end
      end

      response = http_client_with_auth.post(build_url(NUMBERS_ENDPOINT, "/#{@number_id}/messages/native/send"), json: { to: Phonelib.parse(@to).e164, body: @body })
      if response.status.success?
        @errors << "Erreur lors de la mise à jour de l'event d'envoi de message pour #{@to}." unless update_event(2, JSON.parse(response.body)['id'])
      else
        @errors << { message: "L'envoi du message Aircall a échoué : #{response.status.reason}", status: response.status.to_i }
        raise StandardError, "Aircall API request failed : #{response.status.reason}, status: #{response.status.to_i}"
      end
      self
    end

    private

    def update_event(status, aircall_message_id = nil)
      return false unless @event

      @event.update(spot_hit_status: status, aircall_message_id: aircall_message_id)
    end
  end
end
