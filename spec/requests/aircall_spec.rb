require 'rails_helper'

RSpec.describe AircallController, type: :request do
  let(:payload) { { 'data' => { 'some' => 'data' } } }

  describe '/aircall/messages' do
    let(:message_valid_token) { ENV['AIRCALL_WEBHOOK_MESSAGE_TOKEN'] }
    context 'with valid token' do
      it 'returns success and calls the service' do
        service_double = instance_double(Aircall::CreateOrUpdateMessageService, call: double(errors: []))
        allow(Aircall::CreateOrUpdateMessageService).to receive(:new).and_return(service_double)

        post :'/aircall/messages', params: payload.merge(token: message_valid_token)

        expect(response).to have_http_status(:ok)
        expect(Aircall::CreateOrUpdateMessageService).to have_received(:new).with(payload: payload['data'])
      end

      it 'logs to Rollbar when service has errors' do
        service_double = instance_double(Aircall::CreateOrUpdateMessageService, call: double(errors: ['error']))
        allow(Aircall::CreateOrUpdateMessageService).to receive(:new).and_return(service_double)
        allow(Rollbar).to receive(:error)

        post :'/aircall/messages', params: payload.merge(token: message_valid_token)

        expect(Rollbar).to have_received(:error)
      end
    end

    context 'with invalid token' do
      it 'returns unauthorized' do
        post :'/aircall/messages', params: payload.merge(token: 'invalid_token')

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe '/aircall/calls' do
    let(:call_valid_token) { ENV['AIRCALL_WEBHOOK_CALL_TOKEN'] }

    context 'with valid token' do
      it 'returns success and calls the service' do
        service_double = instance_double(Aircall::CreateCallService, call: double(errors: []))
        allow(Aircall::CreateCallService).to receive(:new).and_return(service_double)

        post :'/aircall/calls', params: payload.merge(token: call_valid_token)

        expect(response).to have_http_status(:ok)
        expect(Aircall::CreateCallService).to have_received(:new).with(payload: payload['data'])
      end

      it 'logs to Rollbar when service has errors' do
        service_double = instance_double(Aircall::CreateCallService, call: double(errors: ['error']))
        allow(Aircall::CreateCallService).to receive(:new).and_return(service_double)
        allow(Rollbar).to receive(:error)

        post :'/aircall/calls', params: payload.merge(token: call_valid_token)

        expect(Rollbar).to have_received(:error)
      end
    end

    context 'with invalid token' do
      it 'returns unauthorized' do
        post :'/aircall/calls', params: payload.merge(token: 'invalid_token')

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe '/aircall/insight_cards' do
    let(:insight_card_valid_token) { ENV['AIRCALL_WEBHOOK_INSIGHT_CARDS_TOKEN'] }

    context 'with valid token' do
      it 'returns success and calls the service' do
        service_double = instance_double(Aircall::CreateInsightCardService, call: double(errors: []))
        allow(Aircall::CreateInsightCardService).to receive(:new).and_return(service_double)

        post :'/aircall/insight_cards', params: payload.merge(token: insight_card_valid_token)

        expect(response).to have_http_status(:ok)
        expect(Aircall::CreateInsightCardService).to have_received(:new).with(payload: payload['data'])
      end
    end

    context 'with invalid token' do
      it 'returns unauthorized' do
        post :'/aircall/insight_cards', params: payload.merge(token: 'invalid_token')

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe '/aircall/events_messages_status_updated' do
    let(:valid_token) { ENV['AIRCALL_WEBHOOK_EVENT_MESSAGE_STATUS_UPDATED_TOKEN'] }

    context 'with valid token' do
      it 'returns success and calls the service' do
        service_double = instance_double(Aircall::EventMessageStatusUpdatedService, call: double(errors: []))
        allow(Aircall::EventMessageStatusUpdatedService).to receive(:new).and_return(service_double)

        post :'/aircall/events_messages_status_updated', params: payload.merge(token: valid_token)

        expect(response).to have_http_status(:ok)
        expect(Aircall::EventMessageStatusUpdatedService).to have_received(:new).with(payload: payload['data'])
      end
    end

    context 'with invalid token' do
      it 'returns unauthorized' do
        post :'/aircall/events_messages_status_updated', params: payload.merge(token: 'invalid_token')

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
