require 'rails_helper'

RSpec.describe BlockedSendAttempt::UrlSendGuard do
  let(:allowed_url) { 'https://partenaire.fr/page' }
  let(:blocked_url) { 'https://non-whitelisted.example.com/page' }

  before do
    FactoryBot.create(:allowed_pattern, kind: 'url', match_type: 'domain', value: 'partenaire.fr')
  end

  describe '#blocked_urls' do
    it 'ne retient que les URLs absentes de la whitelist' do
      guard = described_class.new("Voici #{allowed_url} et #{blocked_url}", provider: 'spothit')

      expect(guard.blocked_urls).to eq([blocked_url])
    end

    it 'renvoie un tableau vide quand le texte ne contient aucune URL' do
      guard = described_class.new('Bonjour, ceci est un message sans lien.', provider: 'spothit')

      expect(guard.blocked_urls).to eq([])
    end
  end

  describe '#blocked?' do
    it 'est true quand une URL non whitelistée est présente' do
      guard = described_class.new(blocked_url, provider: 'spothit')

      expect(guard.blocked?).to be(true)
    end

    it 'est false quand toutes les URLs sont whitelistées' do
      guard = described_class.new(allowed_url, provider: 'spothit')

      expect(guard.blocked?).to be(false)
    end
  end

  describe '#block_send?' do
    around do |example|
      previous = ENV['URL_FILTER_BLOCKING_ENABLED']
      example.run
      ENV['URL_FILTER_BLOCKING_ENABLED'] = previous
    end

    it "est false quand URL_FILTER_BLOCKING_ENABLED n'est pas défini, même si une URL est bloquée (mode surveillance)" do
      ENV.delete('URL_FILTER_BLOCKING_ENABLED')
      guard = described_class.new(blocked_url, provider: 'spothit')

      expect(guard.block_send?).to be(false)
    end

    it 'est true quand URL_FILTER_BLOCKING_ENABLED est défini et une URL est bloquée' do
      ENV['URL_FILTER_BLOCKING_ENABLED'] = 'true'
      guard = described_class.new(blocked_url, provider: 'spothit')

      expect(guard.block_send?).to be(true)
    end

    it 'est false quand URL_FILTER_BLOCKING_ENABLED est défini mais qu\'aucune URL n\'est bloquée' do
      ENV['URL_FILTER_BLOCKING_ENABLED'] = 'true'
      guard = described_class.new(allowed_url, provider: 'spothit')

      expect(guard.block_send?).to be(false)
    end
  end

  describe '#register!' do
    around do |example|
      previous = ENV['URL_FILTER_BLOCKING_ENABLED']
      example.run
      ENV['URL_FILTER_BLOCKING_ENABLED'] = previous
    end

    it 'crée un unique BlockedSendAttempt regroupant toutes les URLs bloquées du message' do
      ENV['URL_FILTER_BLOCKING_ENABLED'] = 'true'
      other_blocked_url = 'https://autre-non-whitelistee.example.com/page'
      guard = described_class.new(
        "Voici #{blocked_url} et #{other_blocked_url}",
        provider: 'aircall',
        replay_params: { message: blocked_url }
      )

      expect { guard.register! }.to change(BlockedSendAttempt, :count).by(1)

      attempt = BlockedSendAttempt.last
      expect(attempt.provider).to eq('aircall')
      expect(attempt.kind).to eq('url')
      expect(attempt.detected_values).to contain_exactly(blocked_url, other_blocked_url)
      expect(attempt.replay_params).to eq('message' => blocked_url)
      expect(attempt.status).to eq('pending')
    end

    it "crée le BlockedSendAttempt avec le statut not_blocked quand URL_FILTER_BLOCKING_ENABLED n'est pas défini" do
      ENV.delete('URL_FILTER_BLOCKING_ENABLED')
      guard = described_class.new(blocked_url, provider: 'aircall')

      guard.register!

      expect(BlockedSendAttempt.last.status).to eq('not_blocked')
    end

    it "ne crée aucun BlockedSendAttempt quand blocked_send_attempt_id est déjà fourni (relance)" do
      existing = FactoryBot.create(:blocked_send_attempt)
      guard = described_class.new(blocked_url, provider: 'spothit', blocked_send_attempt_id: existing.id)

      expect { guard.register! }.not_to change(BlockedSendAttempt, :count)
    end
  end
end
