require 'rails_helper'

RSpec.describe Event::UpdateTextMessageStatusService do
  let(:campaign_id) { '245174' }
  let(:parent1) { FactoryBot.create(:parent, phone_number: '+33612345678') }
  let(:parent2) { FactoryBot.create(:parent, phone_number: '+33687654321') }

  let!(:message1) do
    FactoryBot.create(:text_message, related: parent1, spot_hit_message_id: campaign_id, spot_hit_status: 0)
  end
  let!(:message2) do
    FactoryBot.create(:text_message, related: parent2, spot_hit_message_id: campaign_id, spot_hit_status: 0)
  end

  subject(:service) { described_class.new(message_id_from_spot_hit: campaign_id, status: '1').call }

  def stub_dlr(status:, body:, content_type: 'application/json')
    stub_request(:post, 'https://www.spot-hit.fr/api/dlr')
      .to_return(status: status, body: body, headers: { 'Content-Type' => content_type })
  end

  context 'when the DLR endpoint returns the receipts' do
    before do
      stub_dlr(status: 200, body: { parent1.phone_number => 1, parent2.phone_number => 2 }.to_json)
    end

    it 'updates each message with its receipt status' do
      service
      expect(message1.reload.spot_hit_status).to eq(1)
      expect(message2.reload.spot_hit_status).to eq(2)
    end
  end

  # Non-régression Rollbar #983 : sans cette garde, l'exception faisait tomber le
  # job, et un corps JSON inattendu basculait toute la campagne en statut 4.
  context 'when the DLR endpoint returns a non-JSON body' do
    before do
      allow(Rollbar).to receive(:error)
      stub_dlr(status: 502, body: 'error', content_type: 'text/html')
    end

    it 'does not raise' do
      expect { service }.not_to raise_error
    end

    it 'leaves every status untouched rather than marking the campaign as failed' do
      service
      expect(message1.reload.spot_hit_status).to eq(0)
      expect(message2.reload.spot_hit_status).to eq(0)
    end

    it 'reports the incident to Rollbar' do
      service
      expect(Rollbar).to have_received(:error).with(
        'Event::UpdateTextMessageStatusService: réponse DLR inexploitable',
        hash_including(campaign_id: campaign_id)
      )
    end
  end

  context 'when the DLR endpoint returns a JSON error payload' do
    before do
      allow(Rollbar).to receive(:error)
      stub_dlr(status: 200, body: { 'erreurs' => { '1' => 'Clé API invalide' } }.to_json)
    end

    it 'leaves every status untouched' do
      service
      expect(message1.reload.spot_hit_status).to eq(0)
      expect(message2.reload.spot_hit_status).to eq(0)
    end
  end
end
