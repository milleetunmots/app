require 'rails_helper'

RSpec.describe BlockedSendAttempt::DetectedValuesWhitelister do
  describe '#call' do
    it "whiteliste l'url détectée sous forme exacte" do
      attempt = FactoryBot.create(:blocked_send_attempt, kind: 'url', detected_values: ['https://partenaire.fr/inscription'])

      expect { described_class.new(attempt).call }.to change(AllowedPattern, :count).by(1)

      pattern = AllowedPattern.last
      expect(pattern.kind).to eq('url')
      expect(pattern.match_type).to eq('exact')
      expect(pattern.value).to eq('https://partenaire.fr/inscription')
    end

    # Le guard détecte aussi les liens écrits sans schéma, que la validation d'un
    # pattern `exact` refuserait tels quels.
    it "complète le schéma d'une url détectée sans schéma" do
      attempt = FactoryBot.create(:blocked_send_attempt, kind: 'url', detected_values: ['partenaire.fr/page'])

      values = described_class.new(attempt).call

      expect(values).to eq(['https://partenaire.fr/page'])
      expect(AllowedPattern.last.value).to eq('https://partenaire.fr/page')
    end

    it 'whiteliste le numéro détecté' do
      attempt = FactoryBot.create(:blocked_send_attempt, kind: 'phone_number', detected_values: ['0810123456'])

      values = described_class.new(attempt).call

      expect(values).to eq(['0810123456'])
      expect(AllowedPattern.last).to have_attributes(kind: 'phone_number', match_type: 'exact', value: '0810123456')
    end

    # Un mot-clé vient d'une liste noire curée : l'autoriser une fois ne doit pas
    # la vider en douce.
    it 'ne whiteliste pas un mot-clé : la relance reste ponctuelle' do
      attempt = FactoryBot.create(:blocked_send_attempt, kind: 'keyword', detected_values: ['carte cadeau'])

      expect { described_class.new(attempt).call }.not_to change(AllowedPattern, :count)
      expect(described_class.new(attempt).call).to eq([])
    end

    it "n'ajoute pas de doublon ni ne signale une valeur déjà whitelistée" do
      FactoryBot.create(:allowed_pattern, kind: 'phone_number', match_type: 'exact', value: '0810123456')
      attempt = FactoryBot.create(:blocked_send_attempt, kind: 'phone_number', detected_values: ['0810123456'])

      expect { @values = described_class.new(attempt).call }.not_to change(AllowedPattern, :count)
      expect(@values).to eq([])
    end

    it 'whiteliste les valeurs de plusieurs tentatives en une fois' do
      url_attempt = FactoryBot.create(:blocked_send_attempt, kind: 'url', detected_values: ['https://partenaire.fr/page'])
      phone_attempt = FactoryBot.create(:blocked_send_attempt, kind: 'phone_number', detected_values: ['0810123456'])

      values = described_class.new([url_attempt, phone_attempt]).call

      expect(values).to match_array(['https://partenaire.fr/page', '0810123456'])
      expect(AllowedPattern.count).to eq(2)
    end

    # On est sur le chemin d'une relance réussie : le message est déjà parti, une
    # valeur impossible à whitelister ne doit pas faire échouer l'opération.
    it 'signale sans lever une valeur que le modèle refuse' do
      attempt = FactoryBot.create(:blocked_send_attempt, kind: 'phone_number', detected_values: ['ab'])

      expect(Rollbar).to receive(:warning).once

      expect { expect(described_class.new(attempt).call).to eq([]) }.not_to change(AllowedPattern, :count)
    end
  end
end
