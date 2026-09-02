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
            service = described_class.new([parent.id], planned_timestamp, message).call
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
            service = described_class.new([parent.id], planned_timestamp, message).call
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
              [parent.id],
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
        recipients = { parent.id => { 'URL' => 'https://non-whitelisted.example.com/page' } }

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
        recipients = { parent.id => { 'URL' => 'https://partenaire.fr/video' } }

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
          service = described_class.new([parent.id], planned_timestamp, 'Faites un virement immédiat').call
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
        service = described_class.new([parent.id], planned_timestamp, message).call

        expect(service.errors).to be_empty
        expect(WebMock).to have_requested(:post, 'https://www.spot-hit.fr/api/envoyer/sms').once
      end
    end
  end

  describe '#call / create_events' do
    let(:message) { 'Bonjour {PRENOM_ENFANT} !' }

    before do
      stub_request(:post, 'https://www.spot-hit.fr/api/envoyer/sms')
        .to_return(status: 200, body: { id: 4242 }.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    subject(:service) { described_class.new(recipients, planned_timestamp, message).call }

    context 'when two parents share the same phone number' do
      let(:shared_phone) { '+33612349999' }
      let!(:old_parent) { FactoryBot.create(:parent, phone_number: shared_phone, first_name: 'Ancien') }
      let!(:new_parent) { FactoryBot.create(:parent, phone_number: shared_phone, first_name: 'Nouveau') }

      context 'when recipients is a Hash keyed by parent id' do
        let(:recipients) do
          {
            old_parent.id => { 'PRENOM_ENFANT' => 'Emma' },
            new_parent.id => { 'PRENOM_ENFANT' => 'Lucas' }
          }
        end

        it 'sends once and attaches the event to the most recent parent' do
          expect { service }.to change(Event, :count).by(1)
          expect(Event.find_by(related: old_parent)).to be_nil
          expect(Event.find_by(related: new_parent).body).to eq('Bonjour Lucas !')
        end

        it 'sends only the most recent parent variables to Spot Hit' do
          service
          expect(WebMock).to(have_requested(:post, 'https://www.spot-hit.fr/api/envoyer/sms').with do |req|
            body = CGI.unescape(req.body)
            body.include?(shared_phone) && body.include?('Lucas') && body.exclude?('Emma')
          end)
        end
      end

      context 'when recipients is an Array of parent ids' do
        let(:message) { 'Bonjour !' }
        let(:recipients) { [old_parent.id, new_parent.id] }

        it 'creates one event for the most recent parent' do
          expect { service }.to change(Event, :count).by(1)
          expect(Event.last.related_id).to eq(new_parent.id)
        end
      end

      context 'when the parents are parent1 and parent2 of the same child' do
        let!(:child) { FactoryBot.create(:child, parent1: old_parent, parent2: new_parent) }
        let(:recipients) do
          {
            old_parent.id => { 'PRENOM_ENFANT' => 'Emma' },
            new_parent.id => { 'PRENOM_ENFANT' => 'Lucas' }
          }
        end

        it 'prioritizes parent1 even when parent2 is more recent' do
          expect { service }.to change(Event, :count).by(1)
          expect(Event.order(:id).last).to have_attributes(related: old_parent, body: 'Bonjour Emma !')
          expect(WebMock).to(have_requested(:post, 'https://www.spot-hit.fr/api/envoyer/sms').with do |req|
            body = CGI.unescape(req.body)
            body.include?('Emma') && body.exclude?('Lucas')
          end)
        end
      end
    end

    context 'when recipients contains phone numbers instead of parent ids' do
      let(:message) { 'Bonjour !' }
      let!(:parent1) { FactoryBot.create(:parent, phone_number: '+33612345678') }
      let!(:parent2) { FactoryBot.create(:parent, phone_number: '+33687654321') }

      it 'rejects every obsolete phone format without calling Spot Hit' do
        obsolete_formats = [
          [parent1.phone_number, parent2.phone_number],
          { parent1.phone_number => { 'PRENOM_ENFANT' => 'Emma' } },
          "#{parent1.phone_number}, #{parent2.phone_number}"
        ]

        expect {
          obsolete_formats.each do |recipients|
            result = described_class.new(recipients, planned_timestamp, message).call
            expect(result.errors).to eq(['Format de destinataires invalide : utilisez uniquement des identifiants de parents.'])
          end
        }.not_to change(Event, :count)
        expect(WebMock).not_to have_requested(:post, 'https://www.spot-hit.fr/api/envoyer/sms')
      end
    end
  end

  context 'when SPOT_HIT_SAFEGUARD is set' do
    let!(:unsafe_parent) { FactoryBot.create(:parent, phone_number: '+33600000001') }
    let!(:safe_parent) { FactoryBot.create(:parent, phone_number: '+33600000002') }
    let(:message) { 'Bonjour !' }

    around do |example|
      previous_safeguard = ENV['SPOT_HIT_SAFEGUARD']
      previous_safe_numbers = ENV['SAFE_PHONE_NUMBERS']
      ENV['SPOT_HIT_SAFEGUARD'] = 'true'
      ENV['SAFE_PHONE_NUMBERS'] = safe_parent.phone_number
      example.run
      previous_safeguard.nil? ? ENV.delete('SPOT_HIT_SAFEGUARD') : ENV['SPOT_HIT_SAFEGUARD'] = previous_safeguard
      previous_safe_numbers.nil? ? ENV.delete('SAFE_PHONE_NUMBERS') : ENV['SAFE_PHONE_NUMBERS'] = previous_safe_numbers
    end

    it 'creates an event only for the number actually sent' do
      service = described_class.new([unsafe_parent.id, safe_parent.id], planned_timestamp, message)

      expect { service.call }.to change(Event, :count).by(1)
      expect(Event.last.related).to eq(safe_parent)
    end

    it 'does not call Spot Hit when every recipient is filtered out' do
      described_class.new([unsafe_parent.id], planned_timestamp, message).call

      expect(WebMock).not_to have_requested(:post, 'https://www.spot-hit.fr/api/envoyer/sms')
    end
  end
end
