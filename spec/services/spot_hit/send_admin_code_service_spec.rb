require 'rails_helper'

RSpec.describe SpotHit::SendAdminCodeService, type: :service do
  let(:phone_number) { '+33612345678' }
  let(:message) { '1001mots : votre code de connexion est 123456. Il expire dans 10 minutes.' }

  it 'envoie toujours le code immédiatement, même avec une date future' do
    service = described_class.new(phone_number, 1.hour.from_now.to_i, message).call

    expect(service).to be_sent
    expect(WebMock).to have_requested(:post, 'https://www.spot-hit.fr/api/envoyer/sms')
      .with { |request| !URI.decode_www_form(request.body).to_h.key?('date') }
  end

  it 'remonte le motif JSON du refus HTTP 403 sans considérer le code comme envoyé' do
    stub_request(:post, 'https://www.spot-hit.fr/api/envoyer/sms')
      .to_return(status: 403, body: { erreurs: [100] }.to_json, headers: { 'Content-Type' => 'application/json' })

    service = described_class.new(phone_number, Time.current.to_i, message).call

    expect(service).not_to be_sent
    expect(service.errors.join).to include('HTTP 403', '100')
    expect(Event.count).to eq(0)
  end

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
