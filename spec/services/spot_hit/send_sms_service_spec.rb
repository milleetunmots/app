require 'rails_helper'

RSpec.describe SpotHit::SendSmsService do
  let_it_be(:parent, reload: true) { FactoryBot.create(:parent) }
  let(:planned_timestamp) { 1.hour.from_now.to_i }

  before do
    stub_request(:post, 'https://www.spot-hit.fr/api/envoyer/sms').
      to_return(status: 200, body: '{}')
  end

  describe '#call' do
    context 'when the message contains a non-whitelisted URL' do
      let(:message) { 'Cliquez ici : https://non-whitelisted.example.com/page' }

      context 'without URL_FILTER_BLOCKING_ENABLED (monitoring mode, default)' do
        it 'still transmits the message to SpotHit, but tracks a BlockedSendAttempt' do
          service = nil
          expect {
            service = described_class.new([parent.phone_number], planned_timestamp, message).call
          }.to change(BlockedSendAttempt, :count).by(1)

          expect(service.errors).to be_empty
          expect(BlockedSendAttempt.last.detected_values).to eq(['https://non-whitelisted.example.com/page'])
          expect(BlockedSendAttempt.last.status).to eq('not_blocked')
          expect(WebMock).to have_requested(:post, 'https://www.spot-hit.fr/api/envoyer/sms').once
        end
      end

      context 'with URL_FILTER_BLOCKING_ENABLED' do
        around do |example|
          previous = ENV['URL_FILTER_BLOCKING_ENABLED']
          ENV['URL_FILTER_BLOCKING_ENABLED'] = 'true'
          example.run
          ENV['URL_FILTER_BLOCKING_ENABLED'] = previous
        end

        it 'does not call the SpotHit API and creates a BlockedSendAttempt instead' do
          service = nil
          expect {
            service = described_class.new([parent.phone_number], planned_timestamp, message).call
          }.to change(BlockedSendAttempt, :count).by(1)

          expect(service.errors).not_to be_empty
          expect(BlockedSendAttempt.last.detected_values).to eq(['https://non-whitelisted.example.com/page'])
          expect(BlockedSendAttempt.last.status).to eq('pending')
          expect(WebMock).not_to have_requested(:post, 'https://www.spot-hit.fr/api/envoyer/sms')
        end

        it 'does not create a second BlockedSendAttempt when blocked_send_attempt_id is given' do
          existing = FactoryBot.create(:blocked_send_attempt)

          expect {
            described_class.new(
              [parent.phone_number],
              planned_timestamp,
              message,
              blocked_send_attempt_id: existing.id
            ).call
          }.not_to change(BlockedSendAttempt, :count)
        end
      end
    end

    context 'when the message does not contain a non-whitelisted URL' do
      let(:message) { 'Bonjour, ceci est un message sans lien.' }

      it 'transmits the message to SpotHit' do
        service = described_class.new([parent.phone_number], planned_timestamp, message).call

        expect(service.errors).to be_empty
        expect(WebMock).to have_requested(:post, 'https://www.spot-hit.fr/api/envoyer/sms').once
      end
    end
  end
end
