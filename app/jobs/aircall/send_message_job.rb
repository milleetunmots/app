module Aircall
  class SendMessageJob < ApplicationJob
    sidekiq_options retry: 10

    sidekiq_retry_in do |count, exception, _jobhash|
      if exception.message.start_with?('Aircall API rate limit has been reached :')
        reset_at = Time.parse(exception.message.split('reset_at').last.strip)
        wait = reset_at - Time.current
        wait.positive? ? reset_at : 60
      elsif exception.message.starts_with?('Aircall API request failed :')
        60 * 60 * (count + 1) # 60 minutes
      else
        :kill
      end
    end

    sidekiq_retries_exhausted do |job, _ex|
      event = Event.find_by(id: job['args'][0]['arguments'][3])
      event&.update(spot_hit_status: 4)
      Rollbar.error('Aircall::SendMessageService', error: job['error_message'], arguments: job['arguments'])
    end

    def perform(number_id, to, body, event_id)
      service = Aircall::SendMessageService.new(number_id: number_id, to: to, body: body, event_id: event_id).call
      Rollbar.error(service.errors) if service.errors.any?
    end
  end
end
