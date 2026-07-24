require 'rails_helper'

RSpec.describe Aircall::SendMessageService do
  let_it_be(:parent, reload: true) { FactoryBot.create(:parent) }
  let_it_be(:event, reload: true) { FactoryBot.create(:text_message, related: parent) }

  let(:blocked_url) { 'https://non-whitelisted.example.com/page' }

  around do |example|
    previous = ENV['AIRCALL_MESSAGE_ENABLED']
    ENV['AIRCALL_MESSAGE_ENABLED'] = 'true'
    example.run
    ENV['AIRCALL_MESSAGE_ENABLED'] = previous
  end

  describe '#call' do
    context 'quand le message contient une URL non whitelistée' do
      let(:body) { "Cliquez ici : #{blocked_url}" }

      context "sans URL_FILTER_BLOCKING_ENABLED (mode surveillance, par défaut)" do
        it "trace la tentative mais transmet quand même le message au provider" do
          stub_request(:post, 'https://api.aircall.io/v1/numbers/123/messages/native/send').
            to_return(status: 200, body: { id: 'msg_1' }.to_json)

          expect {
            described_class.new(number_id: '123', to: parent.phone_number, body: body, event_id: event.id).call
          }.to change(BlockedSendAttempt, :count).by(1)

          expect(BlockedSendAttempt.last.detected_values).to eq([blocked_url])
          expect(BlockedSendAttempt.last.status).to eq('not_blocked')
          expect(event.reload.spot_hit_status).not_to eq(4)
          expect(WebMock).to have_requested(:post, 'https://api.aircall.io/v1/numbers/123/messages/native/send').once
        end
      end

      context 'avec URL_FILTER_BLOCKING_ENABLED' do
        around do |example|
          previous = ENV['URL_FILTER_BLOCKING_ENABLED']
          ENV['URL_FILTER_BLOCKING_ENABLED'] = 'true'
          example.run
          ENV['URL_FILTER_BLOCKING_ENABLED'] = previous
        end

        it "bloque l'envoi, ne fait aucun appel HTTP, marque l'Event en échec et crée un BlockedSendAttempt" do
          expect {
            described_class.new(number_id: '123', to: parent.phone_number, body: body, event_id: event.id).call
          }.to change(BlockedSendAttempt, :count).by(1)

          attempt = BlockedSendAttempt.last
          expect(attempt.provider).to eq('aircall')
          expect(attempt.detected_values).to eq([blocked_url])
          expect(attempt.status).to eq('pending')
          expect(event.reload.spot_hit_status).to eq(4)
          expect(WebMock).not_to have_requested(:post, %r{https://api\.aircall\.io})
        end

        it 'ne crée pas de second BlockedSendAttempt quand blocked_send_attempt_id est fourni' do
          existing = FactoryBot.create(:blocked_send_attempt)

          expect {
            described_class.new(
              number_id: '123',
              to: parent.phone_number,
              body: body,
              event_id: event.id,
              blocked_send_attempt_id: existing.id
            ).call
          }.not_to change(BlockedSendAttempt, :count)
        end
      end
    end

    context 'quand le message ne contient aucune URL non whitelistée' do
      let(:body) { 'Bonjour, ceci est un message sans lien.' }

      it 'transmet réellement le message au provider Aircall' do
        stub_request(:post, 'https://api.aircall.io/v1/numbers/123/messages/native/send').
          to_return(status: 200, body: { id: 'msg_1' }.to_json)

        service = described_class.new(number_id: '123', to: parent.phone_number, body: body, event_id: event.id).call

        expect(service.errors).to be_empty
        expect(WebMock).to have_requested(:post, 'https://api.aircall.io/v1/numbers/123/messages/native/send').once
      end
    end
  end
end
