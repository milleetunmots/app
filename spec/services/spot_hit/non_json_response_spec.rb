require 'rails_helper'

# Non-régression Rollbar #983 : Spot-Hit répond parfois en texte brut ou en HTML
# (502, maintenance, throttling). Le JSON.parse direct levait alors une
# JSON::ParserError qui faisait échouer le job appelant en entier.
RSpec.describe 'SpotHit avec une réponse non-JSON' do
  let(:parent) { FactoryBot.create(:parent, phone_number: '+33612345678') }
  let(:planned_timestamp) { 1.hour.from_now.to_i }
  let(:message) { 'Bonjour !' }

  describe SpotHit::SendSmsService do
    subject(:service) { described_class.new([parent.id], planned_timestamp, message).call }

    before do
      stub_request(:post, 'https://www.spot-hit.fr/api/envoyer/sms')
        .to_return(status: 502, body: 'error', headers: { 'Content-Type' => 'text/html' })
    end

    it 'does not raise' do
      expect { service }.not_to raise_error
    end

    it 'reports the failure through errors instead' do
      expect(service.errors).not_to be_empty
      expect(service.errors.first).to include('502')
    end

    it 'does not create any event' do
      expect { service }.not_to change(Event, :count)
    end
  end

  describe SpotHit::SendRcsService do
    subject(:service) do
      described_class.new(
        recipients: [parent.id],
        planned_timestamp: planned_timestamp,
        media_id: 42,
        fallback_message: message
      ).call
    end

    before do
      stub_request(:post, 'https://www.spot-hit.fr/api/envoyer/rcs')
        .to_return(status: 200, body: 'error', headers: { 'Content-Type' => 'text/html' })
    end

    it 'does not raise' do
      expect { service }.not_to raise_error
    end

    it 'reports the failure through errors instead' do
      expect(service.errors).not_to be_empty
      expect(service.errors.first).to include('Erreur lors de la programmation de la campagne')
    end

    it 'does not create any event' do
      expect { service }.not_to change(Event, :count)
    end
  end
end
