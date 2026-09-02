require 'rails_helper'

# SpotHit::SendMessageService is an abstract base: its methods are protected and
# it has no public entry point of its own. Its shared logic (create_events, et la
# normalisation des destinataires de SpotHit::Recipients) is exercised here through
# the concrete SpotHit::SendSmsService subclass, which is the production path that
# reaches it.
RSpec.describe SpotHit::SendMessageService do
  let(:parent1) { FactoryBot.create(:parent, phone_number: '0612345678') }
  let(:parent2) { FactoryBot.create(:parent, phone_number: '0687654321') }
  let(:message) { 'Bonjour {PRENOM_ENFANT} !' }
  let(:planned_timestamp) { 1.hour.from_now.to_i }

  before do
    stub_request(:post, 'https://www.spot-hit.fr/api/envoyer/sms')
      .to_return(
        status: 200,
        body: { id: 999 }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  # `errors` ne dit pas si l'envoi a eu lieu : une campagne acceptée peut ensuite
  # échouer à s'historiser. C'est `sent?` qui tranche, et ProgramMessageService
  # s'en sert pour décider de rendre ou non le quota réservé.
  describe '#sent?' do
    subject(:service) { SpotHit::SendSmsService.new(recipients, planned_timestamp, message).call }

    let(:recipients) { [parent1.id] }

    it 'est vrai quand Spot-Hit accepte la campagne' do
      expect(service).to be_sent
    end

    it "reste vrai quand la campagne est partie mais qu'un destinataire n'est pas historisable" do
      recipients << -1

      expect(service).to be_sent
      expect(service.errors.first).to include('aucun parent actif ne correspond à l\'identifiant -1')
    end

    it "est faux quand l'API refuse la campagne" do
      stub_request(:post, 'https://www.spot-hit.fr/api/envoyer/sms')
        .to_return(status: 200, body: { erreurs: ['nope'] }.to_json, headers: { 'Content-Type' => 'application/json' })

      expect(service).not_to be_sent
    end
  end

  describe '#call / create_events' do
    subject(:service) do
      SpotHit::SendSmsService.new(recipients, planned_timestamp, message).call
    end

    context 'when recipients is a Hash (avec variables)' do
      let(:recipients) do
        {
          parent1.id => { 'PRENOM_ENFANT' => 'Emma' },
          parent2.id => { 'PRENOM_ENFANT' => 'Lucas' }
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

      it 'stores the spot_hit message id on the events' do
        service
        expect(Event.pluck(:spot_hit_message_id)).to all(eq('999'))
      end

      it 'returns no errors' do
        expect(service.errors).to be_empty
      end
    end

    context 'when recipients is an Array of parent ids' do
      let(:message) { 'Bonjour !' }
      let(:recipients) { [parent1.id, parent2.id] }

      it 'creates one event per recipient' do
        expect { service }.to change(Event, :count).by(2)
      end

      it 'returns no errors' do
        expect(service.errors).to be_empty
      end
    end

    context 'when a recipient has no matching kept parent' do
      let(:message) { 'Bonjour !' }
      let(:discarded_parent) { FactoryBot.create(:parent, phone_number: '0611223344', discarded_at: Time.zone.now) }
      let(:missing_parent_id) { Parent.maximum(:id).to_i + 10_000 }
      let(:recipients) { [parent1.id, missing_parent_id, discarded_parent.id, parent2.id] }

      it 'still creates the events of the other recipients' do
        expect { service }.to change(Event, :count).by(2)
        expect(Event.find_by(related: parent1)).to be_present
        expect(Event.find_by(related: parent2)).to be_present
      end

      it 'does not attach an event to the discarded parent' do
        service
        expect(Event.find_by(related: discarded_parent)).to be_nil
      end

      it 'reports one error per unresolved recipient' do
        expect(service.errors).to contain_exactly(
          "Message non envoyé : aucun parent actif ne correspond à l'identifiant #{missing_parent_id}.",
          "Message non envoyé : aucun parent actif ne correspond à l'identifiant #{discarded_parent.id}."
        )
      end
    end

    # Un {TOKEN} non reconnu laisse toutes les variables vides. L'envoi doit rester
    # en mode `datas` (que Spot Hit rejette) plutôt que de basculer en liste simple
    # et de diffuser le message avec son placeholder non substitué.
    context 'when the message holds an unsupported variable' do
      let(:message) { 'Bonjour {BAD_VARIABLE} !' }
      let(:recipients) { { parent1.id => {}, parent2.id => {} } }

      it 'does not broadcast the un-substituted message as a plain list' do
        service
        expect(WebMock).to(have_requested(:post, 'https://www.spot-hit.fr/api/envoyer/sms').with do |req|
          body = CGI.unescape(req.body)
          body.include?('destinataires_type=datas') && !body.match?(/destinataires=\+\d/)
        end)
      end
    end

    # Le filtre d'URL / mots-clés inspecte aussi les variables destinataires : il
    # doit tolérer un destinataire sans variables plutôt que de faire échouer l'envoi.
    context 'when a recipient carries no variables hash' do
      let(:message) { 'Bonjour !' }
      let(:recipients) { { parent1.id => nil } }

      it 'does not raise and still creates the event' do
        expect { service }.to change(Event, :count).by(1)
        expect(service.errors).to be_empty
      end
    end
  end

  describe 'workshop participations' do
    let(:message) { 'Bonjour !' }
    let(:workshop) { FactoryBot.create(:workshop) }
    let(:recipients) { [parent1.id, parent2.id] }
    subject(:service) do
      SpotHit::SendSmsService.new(recipients, planned_timestamp, message, workshop_id: workshop.id).call
    end

    it 'builds a workshop participation per recipient' do
      expect { service }.to change(Events::WorkshopParticipation, :count).by(2)
    end
  end
end
