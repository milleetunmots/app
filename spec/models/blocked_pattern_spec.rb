# == Schema Information
#
# Table name: blocked_patterns
#
#  id               :bigint           not null, primary key
#  kind             :string           not null
#  normalized_value :string           not null
#  value            :string           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_blocked_patterns_on_kind_and_normalized_value  (kind,normalized_value) UNIQUE
#
require 'rails_helper'

RSpec.describe BlockedPattern, type: :model do
  describe '.normalize' do
    it 'passe en minuscules, retire les accents et réduit les espaces' do
      expect(described_class.normalize("Vérifiéz  votre \n Compte")).to eq('verifiez votre compte')
    end

    it 'renvoie une chaîne vide pour nil' do
      expect(described_class.normalize(nil)).to eq('')
    end

    it 'réduit un espace insécable (U+00A0) comme un espace normal' do
      expect(described_class.normalize("compte bloqué")).to eq('compte bloque')
    end

    it 'normalise une apostrophe typographique (U+2019) comme une apostrophe simple' do
      expect(described_class.normalize("l’argent")).to eq("l'argent")
    end
  end

  describe 'normalisation à la sauvegarde' do
    it 'calcule normalized_value depuis value' do
      pattern = FactoryBot.create(:blocked_pattern, value: 'Compte  Bloqué')

      expect(pattern.normalized_value).to eq('compte bloque')
    end

    it 'refuse deux graphies du même terme (unicité sur la valeur normalisée)' do
      FactoryBot.create(:blocked_pattern, value: 'Vérifié')
      duplicate = FactoryBot.build(:blocked_pattern, value: 'verifie')

      expect(duplicate).not_to be_valid
    end
  end

  describe 'validations' do
    it 'refuse un terme trop court une fois normalisé' do
      expect(FactoryBot.build(:blocked_pattern, value: 'Là')).not_to be_valid
    end

    it 'refuse un kind inconnu' do
      expect(FactoryBot.build(:blocked_pattern, kind: 'emoji')).not_to be_valid
    end

    it 'refuse une valeur sans caractères alphanumériques (ponctuation seule)' do
      expect(FactoryBot.build(:blocked_pattern, value: '!!!')).not_to be_valid
    end

    it 'accepte un terme de 3 lettres alphanumériques minimum' do
      pattern = FactoryBot.build(:blocked_pattern, value: 'sms')
      expect(pattern).to be_valid
    end
  end

  describe '#matches_normalized?' do
    it 'matche sur frontières de mots, pas en sous-chaîne' do
      pattern = FactoryBot.create(:blocked_pattern, value: 'carte')

      expect(pattern.matches_normalized?(described_class.normalize('votre carte est prête'))).to be(true)
      expect(pattern.matches_normalized?(described_class.normalize('il faut écarter ce cas'))).to be(false)
    end

    it 'matche une expression multi-mots malgré casse, accents et espaces multiples' do
      pattern = FactoryBot.create(:blocked_pattern, value: 'compte bloqué')

      expect(pattern.matches_normalized?(described_class.normalize('Votre  COMPTE   bloqué !'))).to be(true)
    end

    it 'matche une expression multi-mots même séparée par un espace insécable (copié depuis Word)' do
      pattern = FactoryBot.create(:blocked_pattern, value: 'compte bloqué')

      expect(pattern.matches_normalized?(described_class.normalize("Votre compte bloqué !"))).to be(true)
    end

    it 'matche un terme avec apostrophe typographique dans le texte scanné' do
      pattern = FactoryBot.create(:blocked_pattern, value: "l'argent")

      expect(pattern.matches_normalized?(described_class.normalize("Envoyez-nous l’argent rapidement"))).to be(true)
    end

    it 'traite les caractères spéciaux regex littéralement (Regexp.escape)' do
      pattern = FactoryBot.create(:blocked_pattern, value: 'gains 100% garantis')

      # Le pattern doit matcher le texte littéral, pas une interprétation regex du %
      expect(pattern.matches_normalized?(described_class.normalize('gains 100% garantis'))).to be(true)
      # Ne doit pas matcher une interprétation arbitraire regex
      expect(pattern.matches_normalized?(described_class.normalize('gains 100x garantis'))).to be(false)
    end

    it 'échappe les métacaractères de regex comme un point' do
      pattern = FactoryBot.create(:blocked_pattern, value: 'fichier.txt')

      # Doit matcher le point littéral, pas "n\'importe quel caractère"
      expect(pattern.matches_normalized?(described_class.normalize('fichier.txt'))).to be(true)
      expect(pattern.matches_normalized?(described_class.normalize('fichieratxt'))).to be(false)
    end
  end
end
