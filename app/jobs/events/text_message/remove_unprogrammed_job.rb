module Events
  class TextMessage

    class RemoveUnprogrammedJob < ApplicationJob

      def perform
        messages_by_campaign.each do |(product, spot_hit_id), messages|
          reconcile_campaign(product, spot_hit_id, messages)
          sleep(1)
        rescue StandardError => e
          Rails.logger.error("[Events::TextMessage::RemoveUnprogrammedJob] campagne #{product} #{spot_hit_id} : #{e.class} - #{e.message}")
          next
        end
      end

      private

      def reconcile_campaign(product, spot_hit_id, messages)
        check = spothit_check(
          key: ENV.fetch('SPOT_HIT_API_KEY', nil),
          id: spot_hit_id,
          product: product,
          date_start: messages.map(&:occurred_at).min.prev_day.to_i,
          date_end: messages.map(&:occurred_at).max.next_day.to_i
        )
        if check.nil?
          messages.each(&:destroy)
        else
          status = status_from_campaign(check[5].to_i)
          messages.each do |message|
            message.spot_hit_status = status
            message.save(validate: false)
          end
        end
      end

      # Les envois SpotHit sont des campagnes : plusieurs events partagent le même
      # spot_hit_message_id (SMS) ou spot_hit_rcs_id (RCS). On interroge l'API une
      # seule fois par campagne. Les messages sans identifiant SpotHit sont ignorés.
      def messages_by_campaign
        Events::TextMessage.sent_by_app_text_messages.where(spot_hit_status: 0).group_by do |message|
          if message.spot_hit_message_id.present?
            ['sms', message.spot_hit_message_id]
          elsif message.spot_hit_rcs_id.present?
            ['rcs', message.spot_hit_rcs_id]
          end
        end.except(nil)
      end

      # Statut d'envoi de la campagne SpotHit [
      # 0 = Programmé,
      # 1 = En cours,
      # 2 = Envoyé,
      # 3 = En cours,
      # 4 = Echec,
      # 5 = Brouillon]
      def status_from_campaign(campaign_status)
        case campaign_status
        when 1, 3
          3
        when 2
          2
        when 4
          4
        else
          # Programmé, Brouillon ou statut inconnu : reste en attente,
          # la campagne sera re-vérifiée au prochain passage du job
          0
        end
      end

      def spothit_check(params)
        raw_response = HTTP.get('https://www.spot-hit.fr/api/campaign/list', params: params)
        response = JSON.parse(raw_response.body.to_s)
        if response.is_a?(Hash) && response.key?('erreurs')
          raise "Error: #{response}"
        elsif response.empty?
          nil
          # response looks like
          # [ [ "245174", "test2", "", "1", "1681370520", "0", "", "sms", "1681284185", "+33637572453" ] ]
          # so an empty array means the message does not exist in spothit
        else
          response.first
        end
      end
    end
  end
end
