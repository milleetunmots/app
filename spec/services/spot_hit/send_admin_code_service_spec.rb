require 'rails_helper'

RSpec.describe SpotHit::SendAdminCodeService, type: :service do
  let(:phone_number) { '+33612345678' }
  let(:message) { '1001mots : votre code de connexion est 123456. Il expire dans 10 minutes.' }

  it 'poste le message à Spot Hit pour le bon destinataire' do
    described_class.new(phone_number, Time.zone.now.to_i, message).call

    expect(WebMock).to have_requested(:post, 'https://www.spot-hit.fr/api/envoyer/sms')
      .with { |request| request.body.include?(CGI.escape(phone_number)) && request.body.include?('code+de+connexion') }
  end

  it 'ne crée aucun Event, même si un parent porte le même numéro' do
    FactoryBot.create(:parent, phone_number: phone_number)

    expect {
      described_class.new(phone_number, Time.zone.now.to_i, message).call
    }.not_to change(Event, :count)
  end

  it 'ne remonte pas d’erreur pour un message de code (pas d’URL à filtrer)' do
    service = described_class.new(phone_number, Time.zone.now.to_i, message).call
    expect(service.errors).to be_empty
  end

  it 'ignore le filtre de mots-clés : un pattern qui matche le message de code ne bloque ni ne trace rien' do
    FactoryBot.create(:blocked_pattern, value: 'code')

    service = nil
    expect {
      service = described_class.new(phone_number, Time.zone.now.to_i, message).call
    }.not_to change(BlockedSendAttempt, :count)

    expect(service.errors).to be_empty
    expect(WebMock).to have_requested(:post, 'https://www.spot-hit.fr/api/envoyer/sms').once
  end
end
