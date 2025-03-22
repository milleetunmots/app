module Aircall
  class SendMessageJob < ApplicationJob
    sidekiq_options retry: 15

    sidekiq_retry_in do |count, exception, _jobhash|
      case exception.message
      when 'Aircall API request failed'
        60 * (count + 1)
      else
        :kill
      end
    end

    sidekiq_retries_exhausted do |_job, _ex|
      Rollbar.error(@service.errors) if @service.errors.any?
    end

    def perform(parent_id, number_id, to, body)
      @service = Aircall::SendMessageService.new(parent_id: parent_id, number_id: number_id, to: to, body: body).call
    end
  end
end
