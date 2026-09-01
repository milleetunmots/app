require 'rails_helper'

# SpotHit::SendMessageService is an abstract base: its methods are protected and
# it has no public entry point of its own. Its shared logic (create_events /
# resolve_parent) is exercised here through the concrete SpotHit::SendSmsService
# subclass, which is the production path that reaches it.
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

      it 'stores the spot_hit message id on the events' do
        service
        expect(Event.pluck(:spot_hit_message_id)).to all(eq('999'))
      end

      it 'returns no errors' do
        expect(service.errors).to be_empty
      end
    end

    context 'when recipients is an Array of phone strings' do
      let(:message) { 'Bonjour !' }
      let(:recipients) { [parent1.phone_number, parent2.phone_number] }

      it 'creates one event per recipient' do
        expect { service }.to change(Event, :count).by(2)
      end

      it 'returns no errors' do
        expect(service.errors).to be_empty
      end
    end

    context 'when recipients is a String comma-separated' do
      let(:message) { 'Bonjour !' }
      let(:recipients) { "#{parent1.phone_number}, #{parent2.phone_number}" }

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
      let(:recipients) { [parent1.phone_number, '+33699999999', discarded_parent.phone_number, parent2.phone_number] }

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
          "Impossible d'enregistrer le message dans l'historique : Parent non trouvé pour le numéro de téléphone +33699999999.",
          "Impossible d'enregistrer le message dans l'historique : Parent non trouvé pour le numéro de téléphone #{discarded_parent.phone_number}."
        )
      end
    end

    context 'when several kept parents share the same phone number' do
      let(:message) { 'Bonjour !' }
      let!(:parent_a) { FactoryBot.create(:parent, phone_number: '0655667788') }
      let!(:parent_b) { FactoryBot.create(:parent, phone_number: '0655667788') }
      let(:recipients) { [parent_a.phone_number] }

      it 'creates a single event without raising or erroring' do
        expect { service }.to change(Event, :count).by(1)
        expect(service.errors).to be_empty
      end

      it 'attaches the event to one of the parents sharing the number' do
        service
        expect([parent_a.id, parent_b.id]).to include(Event.last.related_id)
      end
    end
  end

  describe 'workshop participations' do
    let(:message) { 'Bonjour !' }
    let(:workshop) { FactoryBot.create(:workshop) }
    let(:recipients) { [parent1.phone_number, parent2.phone_number] }
    subject(:service) do
      SpotHit::SendSmsService.new(recipients, planned_timestamp, message, workshop_id: workshop.id).call
    end

    it 'builds a workshop participation per recipient' do
      expect { service }.to change(Events::WorkshopParticipation, :count).by(2)
    end
  end
end
