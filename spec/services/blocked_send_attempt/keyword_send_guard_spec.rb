require 'rails_helper'

RSpec.describe BlockedSendAttempt::KeywordSendGuard do
  describe '#blocked_values' do
    it 'détecte un terme malgré casse et accents, sur frontières de mots' do
      FactoryBot.create(:blocked_pattern, value: 'virement')
      FactoryBot.create(:blocked_pattern, value: 'carte')

      guard = described_class.new('Faites un VIREMENT sans écarter ce cas', provider: 'spothit')

      expect(guard.blocked_values).to eq(['virement'])
    end

    it 'détecte une expression multi-mots' do
      FactoryBot.create(:blocked_pattern, value: 'compte bloqué')

      guard = described_class.new('Votre compte   bloqué : agissez vite', provider: 'spothit')

      expect(guard.blocked_values).to eq(['compte bloqué'])
    end

    it 'scanne aussi les extra_texts (variables destinataires)' do
      FactoryBot.create(:blocked_pattern, value: 'virement')

      guard = described_class.new('Message sain : {URL}', provider: 'spothit', extra_texts: ['faites un virement ici'])

      expect(guard.blocked?).to be(true)
    end

    it 'est un no-op quand la table est vide' do
      guard = described_class.new('Faites un virement immédiat', provider: 'spothit')

      expect(guard.blocked?).to be(false)
    end
  end

  describe '#block_send? / #register!' do
    around do |example|
      previous = ENV['KEYWORD_FILTER_BLOCKING_ENABLED']
      example.run
      previous.nil? ? ENV.delete('KEYWORD_FILTER_BLOCKING_ENABLED') : ENV['KEYWORD_FILTER_BLOCKING_ENABLED'] = previous
    end

    it 'trace en not_blocked sans bloquer quand le flag est absent (surveillance)' do
      ENV.delete('KEYWORD_FILTER_BLOCKING_ENABLED')
      FactoryBot.create(:blocked_pattern, value: 'virement')
      guard = described_class.new('un virement suspect', provider: 'aircall')

      expect(guard.block_send?).to be(false)
      expect { guard.register! }.to change(BlockedSendAttempt, :count).by(1)
      expect(BlockedSendAttempt.last).to have_attributes(kind: 'keyword', status: 'not_blocked', detected_values: ['virement'])
    end

    it 'bloque et trace en pending quand le flag est actif' do
      ENV['KEYWORD_FILTER_BLOCKING_ENABLED'] = 'true'
      FactoryBot.create(:blocked_pattern, value: 'virement')
      guard = described_class.new('un virement suspect', provider: 'aircall')

      expect(guard.block_send?).to be(true)
      guard.register!
      expect(BlockedSendAttempt.last).to have_attributes(kind: 'keyword', status: 'pending')
    end
  end
end
