module Aircall
  class SendMessageJob < ApplicationJob
    sidekiq_options retry: 10

    sidekiq_retry_in do |count, exception, _jobhash|
      if exception.message.starts_with?('NoRollbarError')
        60 * 60 * (count + 1) # 60 minutes
      else
        :kill
      end
    end

    sidekiq_retries_exhausted do |job, _ex|
      event = Event.find_by(id: job['args'][0]['arguments'][3])
      event&.update(spot_hit_status: 4)
      Rollbar.error('Aircall::SendMessageJob', error: job['error_message'], arguments: job['args'][0]['arguments'])
    end

    def perform(number_id, to, body, event_id)
      service = Aircall::SendMessageService.new(number_id: number_id, to: to, body: body, event_id: event_id).call
      return unless service.errors.any?

      error = service.errors.first
      if error.is_a?(Hash)
        Rollbar.error("Erreur API Aircall : #{error[:key]}", message: error[:message], status: error[:status])
        raise NoRollbarError
      else
        Rollbar.error(error)
      end
    end
  end
end
