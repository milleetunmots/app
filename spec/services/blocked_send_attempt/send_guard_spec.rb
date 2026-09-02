require 'rails_helper'

RSpec.describe BlockedSendAttempt::SendGuard do
  around do |example|
    previous = %w[URL_FILTER_BLOCKING_ENABLED KEYWORD_FILTER_BLOCKING_ENABLED PHONE_NUMBER_FILTER_BLOCKING_ENABLED].index_with { |flag| ENV[flag] }
    previous.each_key { |flag| ENV[flag] = 'true' }
    example.run
    previous.each { |flag, value| value.nil? ? ENV.delete(flag) : ENV[flag] = value }
  end

  it 'bloque et trace kind url quand seule une URL non whitelistée est détectée' do
    guard = described_class.new('Voir https://non-whitelisted.example.com/page', provider: 'spothit')

    expect(guard.block_send?).to be(true)
    expect { guard.register! }.to change(BlockedSendAttempt, :count).by(1)
    expect(BlockedSendAttempt.last.kind).to eq('url')
  end

  it 'bloque et trace kind keyword quand seul un terme interdit est détecté' do
    FactoryBot.create(:blocked_pattern, value: 'virement')
    guard = described_class.new('Faites un virement rapidement', provider: 'spothit')

    expect(guard.block_send?).to be(true)
    expect { guard.register! }.to change(BlockedSendAttempt, :count).by(1)
    expect(BlockedSendAttempt.last.kind).to eq('keyword')
  end

  it 'bloque et trace kind phone_number quand seul un numéro surtaxé est détecté' do
    guard = described_class.new('Appelez le 0890 12 34 56', provider: 'spothit')

    expect(guard.block_send?).to be(true)
    expect { guard.register! }.to change(BlockedSendAttempt, :count).by(1)
    expect(BlockedSendAttempt.last.kind).to eq('phone_number')
  end

  it 'crée un attempt par kind quand URL et terme sont détectés ensemble' do
    FactoryBot.create(:blocked_pattern, value: 'virement')
    guard = described_class.new('virement ici : https://non-whitelisted.example.com/page', provider: 'spothit')

    expect { guard.register! }.to change(BlockedSendAttempt, :count).by(2)
    expect(BlockedSendAttempt.order(:id).last(2).map(&:kind)).to contain_exactly('url', 'keyword')
  end

  it "expose un message d'erreur générique qui ne révèle ni la cause ni les valeurs" do
    guard = described_class.new('peu importe', provider: 'spothit')

    expect(guard.error_message).to eq('Ce message ne peut pas être envoyé, veuillez contacter le pôle tech.')
  end

  it "en relance d'un attempt url, ne re-trace pas l'url mais trace un terme nouvellement blacklisté" do
    url_attempt = FactoryBot.create(:blocked_send_attempt, kind: 'url')
    FactoryBot.create(:blocked_pattern, value: 'virement')
    guard = described_class.new(
      'virement ici : https://non-whitelisted.example.com/page',
      provider: 'spothit',
      blocked_send_attempt_id: url_attempt.id
    )

    expect { guard.register! }.to change(BlockedSendAttempt, :count).by(1)
    expect(BlockedSendAttempt.last.kind).to eq('keyword')
  end

  # Une relance décidée par un super_admin est un feu vert humain sur un contenu
  # déjà relu dans l'admin : plus aucun contrôle ne doit la bloquer.
  context 'en relance forcée par un admin (force_send)' do
    it "ne bloque pas, même quand l'URL est toujours interdite" do
      attempt = FactoryBot.create(:blocked_send_attempt, kind: 'url', force_send: true)
      guard = described_class.new(
        'Voir https://non-whitelisted.example.com/page',
        provider: 'spothit',
        blocked_send_attempt_id: attempt.id
      )

      expect(guard.blocked?).to be(false)
      expect(guard.block_send?).to be(false)
    end

    it "ne bloque pas non plus sur une cause nouvelle d'un autre kind" do
      attempt = FactoryBot.create(:blocked_send_attempt, kind: 'url', force_send: true)
      FactoryBot.create(:blocked_pattern, value: 'virement')
      guard = described_class.new(
        'virement ici : https://non-whitelisted.example.com/page',
        provider: 'spothit',
        blocked_send_attempt_id: attempt.id
      )

      expect(guard.block_send?).to be(false)
      expect { guard.register! }.not_to change(BlockedSendAttempt, :count)
    end

    it 'bloque toujours quand la tentative référencée ne force pas (mode surveillance)' do
      attempt = FactoryBot.create(:blocked_send_attempt, kind: 'keyword', status: 'not_blocked')
      guard = described_class.new(
        'Voir https://non-whitelisted.example.com/page',
        provider: 'spothit',
        blocked_send_attempt_id: attempt.id
      )

      expect(guard.block_send?).to be(true)
    end
  end
end
