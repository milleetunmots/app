module Aircall
  class SendMessageService < Aircall::ApiBase
    attr_reader :errors

    def initialize(parent_id:, number_id:, to:, body:)
      @errors = []
      @number_id = number_id
      @to = to
      @body = body
      @parent_id = parent_id
    end

    def call
      return self unless ENV['AIRCALL_ENABLED']
      @errors << "Envoi impossible à cause de paramètres invalides" and return self if @to.blank? || @number_id.blank?

      if Rails.env.development? || ENV['SPOT_HIT_SAFEGUARD'].present?
        safe_numbers = ENV['SAFE_PHONE_NUMBERS'].to_s.split(',').map(&:strip)
        @errors << "Numéro invalide : il n'est pas whitelisté" and return self unless safe_numbers.include?(@to)
      end

      response = http_client_with_auth.post(build_url(NUMBERS_ENDPOINT, "/#{@number_id}/messages/native/send"), json: { to: Phonelib.parse(@to).e164, body: @body })
      if response.status.success?
        event = Event.find_by(related_id: @parent_id, body: @body)
        @errors << "Erreur lors de la mise à jour de l'event d'envoi de message pour #{parent.phone_number}." unless event.update(spot_hit_status: 2, aircall_message_id: JSON.parse(response.body)['id'])
      else
        @errors << { message: "L'envoi du message Aircall a échoué : #{response.status.reason}", status: response.status.to_i }
        raise StandardError, 'Aircall API request failed'
      end
      self
    end
  end
end
