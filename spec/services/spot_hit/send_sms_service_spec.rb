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
        around do |example|
          previous = ENV['URL_FILTER_BLOCKING_ENABLED']
          ENV.delete('URL_FILTER_BLOCKING_ENABLED')
          example.run
          ENV['URL_FILTER_BLOCKING_ENABLED'] = previous
        end

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

    context 'when a recipient variable contains a URL (message itself clean)' do
      let(:message) { 'Regardez cette vidéo : {URL}' }

      around do |example|
        previous = ENV['URL_FILTER_BLOCKING_ENABLED']
        ENV['URL_FILTER_BLOCKING_ENABLED'] = 'true'
        example.run
        ENV['URL_FILTER_BLOCKING_ENABLED'] = previous
      end

      it 'blocks the send when the substituted value is not whitelisted' do
        recipients = { parent.phone_number => { 'URL' => 'https://non-whitelisted.example.com/page' } }

        service = nil
        expect {
          service = described_class.new(recipients, planned_timestamp, message).call
        }.to change(BlockedSendAttempt, :count).by(1)

        expect(service.errors).not_to be_empty
        expect(BlockedSendAttempt.last.detected_values).to eq(['https://non-whitelisted.example.com/page'])
        expect(WebMock).not_to have_requested(:post, 'https://www.spot-hit.fr/api/envoyer/sms')
      end

      it 'still sends when the substituted value is whitelisted' do
        FactoryBot.create(:allowed_pattern, kind: 'url', match_type: 'domain', value: 'partenaire.fr')
        recipients = { parent.phone_number => { 'URL' => 'https://partenaire.fr/video' } }

        service = described_class.new(recipients, planned_timestamp, message).call

        expect(service.errors).to be_empty
        expect(WebMock).to have_requested(:post, 'https://www.spot-hit.fr/api/envoyer/sms').once
      end
    end

    context 'when the message contains a blocked keyword' do
      around do |example|
        previous = ENV['KEYWORD_FILTER_BLOCKING_ENABLED']
        ENV['KEYWORD_FILTER_BLOCKING_ENABLED'] = 'true'
        example.run
        previous.nil? ? ENV.delete('KEYWORD_FILTER_BLOCKING_ENABLED') : ENV['KEYWORD_FILTER_BLOCKING_ENABLED'] = previous
      end

      it 'blocks the send with a generic error and records a keyword BlockedSendAttempt' do
        FactoryBot.create(:blocked_pattern, value: 'virement')

        service = nil
        expect {
          service = described_class.new([parent.phone_number], planned_timestamp, 'Faites un virement immédiat').call
        }.to change(BlockedSendAttempt, :count).by(1)

        expect(service.errors).to eq(['Ce message ne peut pas être envoyé, veuillez contacter le pôle tech.'])
        expect(BlockedSendAttempt.last).to have_attributes(kind: 'keyword', status: 'pending')
        expect(WebMock).not_to have_requested(:post, 'https://www.spot-hit.fr/api/envoyer/sms')
      end
    end

    context 'garde-fou : le filtre de mots-clés reste actif par défaut (seam content_guard_enabled?)' do
      # SpotHit::SendAdminCodeService désactive ce filtre pour son propre envoi
      # (2FA). Cet exemple garantit que ce n'est pas le filtre lui-même qui a
      # été désactivé pour tout le monde : un envoi ordinaire, avec le même
      # pattern, doit continuer à être tracé.
      it 'trace toujours un BlockedSendAttempt pour un envoi ordinaire' do
        FactoryBot.create(:blocked_pattern, value: 'code')

        expect {
          described_class.new([parent.phone_number], planned_timestamp, 'Voici votre code promo').call
        }.to change(BlockedSendAttempt, :count).by(1)

        expect(BlockedSendAttempt.last).to have_attributes(kind: 'keyword', status: 'not_blocked')
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
