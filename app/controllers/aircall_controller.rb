class AircallController < ApplicationController
  skip_before_action :authenticate_admin_user!
  skip_before_action :verify_authenticity_token
  before_action :verify_webhook_messages_token, only: :webhook_messages
  before_action :verify_webhook_calls_token, only: :webhook_calls

  def webhook_messages
    payload = params.to_unsafe_h
    service = Aircall::CreateOrUpdateMessageService.new(payload: payload['data']).call
    if service.errors.any?
      Rollbar.error('Aircall::CreateOrUpdateMessageService', errors: service.errors)
    end
    head :ok
  end

  def webhook_calls
    payload = params.to_unsafe_h
    service = Aircall::CreateCallService.new(payload: payload['data']).call
    if service.errors.any?
      Rollbar.error('Aircall::CreateCallService', errors: service.errors)
    end
    head :ok
  end

  private

  def verify_webhook_messages_token
    token = params['token']
    head :unauthorized unless token.eql?(ENV['AIRCALL_WEBHOOK_MESSAGE_TOKEN'])
  end

  def verify_webhook_calls_token
    token = params['token']
    head :unauthorized unless token.eql?(ENV['AIRCALL_WEBHOOK_CALL_TOKEN'])
  end
end
