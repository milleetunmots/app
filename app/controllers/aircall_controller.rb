class AircallController < ApplicationController
  skip_before_action :authenticate_admin_user!
  skip_before_action :verify_authenticity_token
  before_action :verify_webhook_messages_token, only: :webhook_messages
  before_action :verify_webhook_calls_token, only: :webhook_calls
  before_action :verify_webhook_insight_cards, only: :webhook_insight_cards
  before_action :verify_webhook_events_messages_status_updated, only: :webhook_events_messages_status_updated

  def webhook_messages
    payload = params.to_unsafe_h
    service = Aircall::CreateOrUpdateMessageService.new(payload: payload['data']).call
    Rollbar.error('Aircall::CreateOrUpdateMessageService', errors: service.errors) if service.errors.any?
    head :ok
  end

  def webhook_calls
    payload = params.to_unsafe_h
    service = Aircall::CreateCallService.new(payload: payload['data']).call
    Rollbar.error('Aircall::CreateCallService', errors: service.errors) if service.errors.any?
    head :ok
  end

  def webhook_insight_cards
    payload = params.to_unsafe_h
    insight_card_service = Aircall::CreateInsightCardService.new(payload: payload['data']).call
    Rollbar.error('Aircall::CreateInsightCardService', errors: insight_card_service.errors) if insight_card_service.errors.any?
    head :ok
  end

  def webhook_events_messages_status_updated
    payload = params.to_unsafe_h
    message_status_updated_service = Aircall::EventMessageStatusUpdatedService.new(payload: payload['data']).call
    Rollbar.error('Aircall::EventMessageStatusUpdatedService', errors: message_status_updated_service.errors) if message_status_updated_service.errors.any?
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

  def verify_webhook_insight_cards
    token = params['token']
    head :unauthorized unless token.eql?(ENV['AIRCALL_WEBHOOK_INSIGHT_CARDS_TOKEN'])
  end

  def verify_webhook_events_messages_status_updated
    token = params['token']
    head :unauthorized unless token.eql?(ENV['AIRCALL_WEBHOOK_EVENT_MESSAGE_STATUS_UPDATED_TOKEN'])
  end
end
