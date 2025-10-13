module Aircall
  class SendBulkMessageJob < ApplicationJob
    sidekiq_options retry: 10

    sidekiq_retry_in do |count, exception, _jobhash|
      if exception.message.starts_with?('NoRollbarError')
        60 * 60 * (count + 1) # 60 minutes
      else
        :kill
      end
    end

    sidekiq_retries_exhausted do |job, _ex|
      job['args'][0]['arguments'][0].each do |recipient|
        event = Event.find_by(id: recipient['event_id'])
        event&.update(spot_hit_status: 4)
      end
      Rollbar.error('Aircall::SendBulkMessageJob', error: job['error_message'], arguments: job['args'][0]['arguments'])
    end

    def perform(recipients)
      errors = []
      recipients.reject { |recipient| Events::TextMessage.find(recipient[:event_id]).spot_hit_status == 2 }.each do |recipient|
        service = Aircall::SendMessageService.new(
          number_id: recipient[:number_id],
          to: recipient[:to],
          body: recipient[:body],
          event_id: recipient[:event_id]
        ).call
        next unless service.errors.any?

        errors << service.errors.first
      end
      return if errors.empty?

      api_errors = errors.select { |error| error.is_a?(Hash) }
      service_errors = errors.select { |error| error.is_a?(Array) }
      if api_errors.any?
        Rollbar.error("Erreur API Aircall : #{api_errors.pluck(:key).uniq}", message: api_errors.pluck(:message).uniq, status: api_errors.pluck(:status).uniq)
        raise NoRollbarError
      end
      Rollbar.error(service_errors.uniq) if service_errors.any?
    end
  end
end
