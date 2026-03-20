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
  end
end
