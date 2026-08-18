require 'rails_helper'

RSpec.describe SpotHit::SendRcsService do
  let(:parent1) { FactoryBot.create(:parent, phone_number: '0612345678') }
  let(:parent2) { FactoryBot.create(:parent, phone_number: '0687654321') }
  let(:media_id) { 42 }
  let(:fallback_message) { 'Bonjour {PRENOM_ENFANT} !' }
  let(:planned_timestamp) { 1.hour.from_now.to_i }

  before do
    stub_request(:post, 'https://www.spot-hit.fr/api/envoyer/rcs')
      .to_return(
        status: 200,
        body: { success: true, campaign_id: 999 }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  # `errors` ne dit pas si l'envoi a eu lieu : une campagne acceptée peut ensuite
  # échouer à s'historiser. C'est `sent?` qui tranche, et ProgramMessageService
  # s'en sert pour décider de rendre ou non le quota réservé.
  describe '#sent?' do
    subject(:service) { described_class.new(recipients: recipients, planned_timestamp: planned_timestamp, fallback_message: fallback_message).call }

    let(:recipients) { [parent1.phone_number] }

    it 'est vrai quand Spot-Hit accepte la campagne' do
      expect(service).to be_sent
    end

    it "reste vrai quand la campagne est partie mais qu'un destinataire n'est pas historisable" do
      recipients << '0600000000'

      expect(service).to be_sent
      expect(service.errors.first).to include('Parent non trouvé')
    end

    it "est faux quand l'API refuse la campagne" do
      stub_request(:post, 'https://www.spot-hit.fr/api/envoyer/rcs')
        .to_return(status: 200, body: { erreurs: ['nope'] }.to_json, headers: { 'Content-Type' => 'application/json' })

      expect(service).not_to be_sent
    end

    it 'est faux quand le contrôle de contenu bloque le message' do
      FactoryBot.create(:blocked_pattern, kind: 'keyword', value: 'interdit')
      ENV['KEYWORD_FILTER_BLOCKING_ENABLED'] = 'true'

      service = described_class.new(recipients: recipients, planned_timestamp: planned_timestamp, fallback_message: 'mot interdit').call

      expect(service).not_to be_sent
      expect(WebMock).not_to have_requested(:post, 'https://www.spot-hit.fr/api/envoyer/rcs')
    ensure
      ENV.delete('KEYWORD_FILTER_BLOCKING_ENABLED')
    end
  end

  describe '#call / create_events' do
    subject(:service) { described_class.new(recipients: recipients, planned_timestamp: planned_timestamp, media_id: media_id, fallback_message: fallback_message).call }

    context 'when recipients is a Hash (avec variables)' do
      let(:recipients) do
        {
          parent1.phone_number => { 'PRENOM_ENFANT' => 'Emma' },
          parent2.phone_number => { 'PRENOM_ENFANT' => 'Lucas' }
        }
      end

      it 'creates one event per recipient' do
        expect { service }.to change(Event, :count).by(2)
      end

      it 'substitutes variables in the event body' do
        service
        expect(Event.find_by(related: parent1).body).to eq('Bonjour Emma !')
        expect(Event.find_by(related: parent2).body).to eq('Bonjour Lucas !')
      end

      it 'returns no errors' do
        expect(service.errors).to be_empty
      end
    end

    context 'when recipients is an Array of strings (sans variables ni redirection)' do
      let(:fallback_message) { 'Bonjour !' }
      let(:recipients) { [parent1.phone_number, parent2.phone_number] }

      it 'creates one event per recipient' do
        expect { service }.to change(Event, :count).by(2)
      end

      it 'returns no errors' do
        expect(service.errors).to be_empty
      end
    end

    context 'when recipients is a String comma-separated' do
      let(:fallback_message) { 'Bonjour !' }
      let(:recipients) { "#{parent1.phone_number}, #{parent2.phone_number}" }

      it 'creates one event per recipient' do
        expect { service }.to change(Event, :count).by(2)
      end

      it 'returns no errors' do
        expect(service.errors).to be_empty
      end
    end

    context 'when the fallback message contains a non-whitelisted URL' do
      let(:fallback_message) { 'Cliquez ici : https://non-whitelisted.example.com/page' }
      let(:recipients) { [parent1.phone_number, parent2.phone_number] }

      context 'without URL_FILTER_BLOCKING_ENABLED (monitoring mode, default)' do
        around do |example|
          previous = ENV['URL_FILTER_BLOCKING_ENABLED']
          ENV.delete('URL_FILTER_BLOCKING_ENABLED')
          example.run
          ENV['URL_FILTER_BLOCKING_ENABLED'] = previous
        end

        it 'still makes the API call and creates events, but also tracks a BlockedSendAttempt' do
          expect { service }.to change(BlockedSendAttempt, :count).by(1)
          expect(BlockedSendAttempt.last.status).to eq('not_blocked')
          expect(WebMock).to have_requested(:post, 'https://www.spot-hit.fr/api/envoyer/rcs')
        end

        it 'creates events' do
          expect { service }.to change(Event, :count).by(2)
        end
      end

      context 'with URL_FILTER_BLOCKING_ENABLED' do
        around do |example|
          previous = ENV['URL_FILTER_BLOCKING_ENABLED']
          ENV['URL_FILTER_BLOCKING_ENABLED'] = 'true'
          example.run
          ENV['URL_FILTER_BLOCKING_ENABLED'] = previous
        end

        it 'does not make an API call and creates a BlockedSendAttempt instead' do
          expect { service }.to change(BlockedSendAttempt, :count).by(1)
          expect(BlockedSendAttempt.last.status).to eq('pending')
          expect(WebMock).not_to have_requested(:post, 'https://www.spot-hit.fr/api/envoyer/rcs')
        end

        it 'does not create any events' do
          expect { service }.not_to change(Event, :count)
        end

        it 'does not create a second BlockedSendAttempt when blocked_send_attempt_id is given' do
          existing = FactoryBot.create(:blocked_send_attempt)
          service = described_class.new(
            recipients: recipients,
            planned_timestamp: planned_timestamp,
            media_id: media_id,
            fallback_message: fallback_message,
            blocked_send_attempt_id: existing.id
          ).call

          expect(service.errors).not_to be_empty
          expect(BlockedSendAttempt.count).to eq(1)
        end
      end
    end

    context 'when a recipient variable contains a URL (fallback message clean)' do
      let(:fallback_message) { 'Regardez cette vidéo : {URL}' }

      around do |example|
        previous = ENV['URL_FILTER_BLOCKING_ENABLED']
        ENV['URL_FILTER_BLOCKING_ENABLED'] = 'true'
        example.run
        ENV['URL_FILTER_BLOCKING_ENABLED'] = previous
      end

      context 'when the substituted value is not whitelisted' do
        let(:recipients) do
          { parent1.phone_number => { 'URL' => 'https://non-whitelisted.example.com/page' } }
        end

        it 'does not make an API call and creates a BlockedSendAttempt instead' do
          expect { service }.to change(BlockedSendAttempt, :count).by(1)
          expect(BlockedSendAttempt.last.detected_values).to eq(['https://non-whitelisted.example.com/page'])
          expect(WebMock).not_to have_requested(:post, 'https://www.spot-hit.fr/api/envoyer/rcs')
        end
      end

      context 'when the substituted value is whitelisted' do
        let(:recipients) do
          { parent1.phone_number => { 'URL' => 'https://partenaire.fr/video' } }
        end

        it 'makes the API call without errors' do
          FactoryBot.create(:allowed_pattern, kind: 'url', match_type: 'domain', value: 'partenaire.fr')

          expect(service.errors).to be_empty
          expect(WebMock).to have_requested(:post, 'https://www.spot-hit.fr/api/envoyer/rcs').once
        end
      end
    end
    
    context 'when a recipient has no matching kept parent' do
      let(:fallback_message) { 'Bonjour !' }
      let(:discarded_parent) { FactoryBot.create(:parent, phone_number: '0611223344', discarded_at: Time.zone.now) }
      let(:recipients) { [parent1.phone_number, '+33699999999', discarded_parent.phone_number, parent2.phone_number] }

      it 'still creates the events of the other recipients' do
        expect { service }.to change(Event, :count).by(2)
        expect(Event.find_by(related: parent1)).to be_present
        expect(Event.find_by(related: parent2)).to be_present
      end

      it 'reports one error per unresolved recipient' do
        expect(service.errors).to contain_exactly(
          "Impossible d'enregistrer le rcs dans l'historique : Parent non trouvé pour le numéro de téléphone +33699999999.",
          "Impossible d'enregistrer le rcs dans l'historique : Parent non trouvé pour le numéro de téléphone #{discarded_parent.phone_number}."
        )
      end
    end

    context 'when SPOT_HIT_SAFEGUARD is set' do
      let(:safe_parent) { FactoryBot.create(:parent, phone_number: '+33600000001') }

      before do
        ENV['SPOT_HIT_SAFEGUARD'] = 'true'
        ENV['SAFE_PHONE_NUMBERS'] = safe_parent.phone_number
      end

      after do
        ENV.delete('SPOT_HIT_SAFEGUARD')
        ENV.delete('SAFE_PHONE_NUMBERS')
      end

      context 'when no recipient is whitelisted' do
        let(:recipients) do
          {
            parent1.phone_number => { 'PRENOM_ENFANT' => 'Emma' },
            parent2.phone_number => { 'PRENOM_ENFANT' => 'Lucas' }
          }
        end

        it 'does not make an API call' do
          service
          expect(WebMock).not_to have_requested(:post, 'https://www.spot-hit.fr/api/envoyer/rcs')
        end

        it 'does not create any events' do
          expect { service }.not_to change(Event, :count)
        end
      end

      context 'when one recipient is whitelisted (Hash format)' do
        let(:recipients) do
          {
            parent1.phone_number => { 'PRENOM_ENFANT' => 'Emma' },
            safe_parent.phone_number => { 'PRENOM_ENFANT' => 'Lucas' }
          }
        end

        it 'makes an API call' do
          service
          expect(WebMock).to have_requested(:post, 'https://www.spot-hit.fr/api/envoyer/rcs')
        end

        it 'only creates an event for the whitelisted recipient' do
          expect { service }.to change(Event, :count).by(1)
          expect(Event.last.related).to eq(safe_parent)
        end
      end

      context 'when one recipient is whitelisted (Array format)' do
        let(:fallback_message) { 'Bonjour !' }
        let(:recipients) { [parent1.phone_number, safe_parent.phone_number] }

        it 'makes an API call' do
          service
          expect(WebMock).to have_requested(:post, 'https://www.spot-hit.fr/api/envoyer/rcs')
        end

        it 'only creates an event for the whitelisted recipient' do
          expect { service }.to change(Event, :count).by(1)
          expect(Event.last.related).to eq(safe_parent)
        end
      end

      context 'when SAFE_PHONE_NUMBERS contains multiple numbers (avec espaces)' do
        let(:safe_parent2) { FactoryBot.create(:parent, phone_number: '+33600000002') }
        let(:recipients) do
          {
            parent1.phone_number => { 'PRENOM_ENFANT' => 'Emma' },
            safe_parent.phone_number => { 'PRENOM_ENFANT' => 'Lucas' },
            safe_parent2.phone_number => { 'PRENOM_ENFANT' => 'Léa' }
          }
        end

        before { ENV['SAFE_PHONE_NUMBERS'] = "#{safe_parent.phone_number}, #{safe_parent2.phone_number}" }

        it 'creates events for both whitelisted recipients only' do
          expect { service }.to change(Event, :count).by(2)
          expect(Event.pluck(:related_id)).to contain_exactly(safe_parent.id, safe_parent2.id)
        end
      end
    end

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

        it 'creates one event per parent, each attached to the right parent' do
          expect { service }.to change(Event, :count).by(2)
          expect(Event.find_by(related: old_parent).body).to eq('Bonjour Emma !')
          expect(Event.find_by(related: new_parent).body).to eq('Bonjour Lucas !')
        end

        it 'sends phone numbers to Spot Hit, not parent ids' do
          service
          expect(WebMock).to(have_requested(:post, 'https://www.spot-hit.fr/api/envoyer/rcs').with do |req|
            req.body.include?(CGI.escape(shared_phone)) && req.body.exclude?("custom_list_with_data%5B#{old_parent.id}%5D")
          end)
        end
      end

      context 'when recipients is an Array of parent ids' do
        let(:fallback_message) { 'Bonjour !' }
        let(:recipients) { [old_parent.id, new_parent.id] }

        it 'creates one event per parent' do
          expect { service }.to change(Event, :count).by(2)
          expect(Event.pluck(:related_id)).to contain_exactly(old_parent.id, new_parent.id)
        end
      end
    end

    context 'when a recipient has been discarded' do
      let(:fallback_message) { 'Bonjour !' }
      let!(:discarded_parent) { FactoryBot.create(:parent, phone_number: '+33612340000') }

      before { discarded_parent.discard }

      context 'when recipients is an Array of parent ids' do
        let(:recipients) { [parent1.id, discarded_parent.id] }

        it 'does not create an event for the discarded parent' do
          expect { service }.to change(Event, :count).by(1)
          expect(Event.last.related).to eq(parent1)
        end

        it 'does not send the message to the discarded parent' do
          service
          expect(WebMock).to(have_requested(:post, 'https://www.spot-hit.fr/api/envoyer/rcs').with do |req|
            req.body.exclude?(CGI.escape(discarded_parent.phone_number))
          end)
        end
      end

      context 'when recipients is a Hash keyed by phone number' do
        let(:recipients) { { discarded_parent.phone_number => { 'PRENOM_ENFANT' => 'Emma' } } }

        it 'creates no event at all' do
          expect { service }.not_to change(Event, :count)
        end
      end
    end
  end
end
