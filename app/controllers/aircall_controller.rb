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
    create_insight_card(payload[:event], payload.dig(:data, :id), Phonelib.parse(payload.dig(:data, :raw_digits)).e164) if payload.dig(:data, :direction) == 'inbound'
    create_call(payload[:data])
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

  def create_insight_card(event, call_id, parent_phone_number)
    return unless event == 'call.created'

    service = Aircall::CreateInsightCardService.new(call_id: call_id, parent_phone_number: parent_phone_number).call
    Rollbar.error('Aircall::CreateInsightCardService', errors: service.errors) if service.errors.any?
  end

  def create_call(data)
    service = Aircall::CreateCallService.new(payload: data).call
    Rollbar.error('Aircall::CreateCallService', errors: service.errors) if service.errors.any?
  end
end
