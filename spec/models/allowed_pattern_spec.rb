# == Schema Information
#
# Table name: allowed_patterns
#
#  id         :bigint           not null, primary key
#  kind       :string           not null
#  match_type :string           not null
#  value      :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_allowed_patterns_on_kind_and_match_type_and_value  (kind,match_type,value) UNIQUE
#

require 'rails_helper'

RSpec.describe AllowedPattern, type: :model do
  describe 'Validations' do
    context 'succeed' do
      it 'avec un domaine autorisé (kind url, match_type domain)' do
        expect(FactoryBot.build(:allowed_pattern, kind: 'url', match_type: 'domain', value: 'monpartenaire.fr')).to be_valid
      end

      it 'avec une url exacte autorisée (kind url, match_type exact)' do
        expect(FactoryBot.build(:allowed_pattern, kind: 'url', match_type: 'exact', value: 'https://bit.ly/evenement-caf-local')).to be_valid
      end
    end

    context 'fail' do
      it "si le kind n'est pas encore supporté (ex: keyword)" do
        expect(FactoryBot.build(:allowed_pattern, kind: 'keyword', match_type: 'domain')).not_to be_valid
      end

      it "si le match_type n'est pas cohérent avec le kind" do
        expect(FactoryBot.build(:allowed_pattern, kind: 'url', match_type: 'contains')).not_to be_valid
      end

      it 'si la combinaison kind/match_type/value existe déjà (doublon)' do
        FactoryBot.create(:allowed_pattern, kind: 'url', match_type: 'domain', value: 'youtube.com')
        expect(FactoryBot.build(:allowed_pattern, kind: 'url', match_type: 'domain', value: 'youtube.com')).not_to be_valid
      end

      it 'si une url complète (avec schéma) est fournie pour un match_type domain' do
        allowed_pattern = FactoryBot.build(:allowed_pattern, kind: 'url', match_type: 'domain', value: 'https://monpartenaire.fr')
        expect(allowed_pattern).not_to be_valid
        expect(allowed_pattern.errors[:value]).to be_present
      end

      it 'si un simple domaine (sans schéma) est fourni pour un match_type exact' do
        allowed_pattern = FactoryBot.build(:allowed_pattern, kind: 'url', match_type: 'exact', value: 'bit.ly')
        expect(allowed_pattern).not_to be_valid
        expect(allowed_pattern.errors[:value]).to be_present
      end
    end
  end

  describe '#destroy' do
    context 'sur un domaine (match_type: domain)' do
      it 'échoue si un Media::Form utilise encore ce domaine' do
        allowed_pattern = FactoryBot.create(:allowed_pattern, kind: 'url', match_type: 'domain', value: 'youtube.com')
        FactoryBot.create(:media_form, url: 'https://www.youtube.com/watch?v=abc123')

        expect(allowed_pattern.destroy).to be false
        expect(allowed_pattern.errors[:base]).to be_present
        expect(AllowedPattern.exists?(allowed_pattern.id)).to be true
      end

      it "réussit si aucun Media::Form n'utilise ce domaine" do
        allowed_pattern = FactoryBot.create(:allowed_pattern, kind: 'url', match_type: 'domain', value: 'monancienpartenaire.fr')

        expect(allowed_pattern.destroy).to eq(allowed_pattern)
        expect(AllowedPattern.exists?(allowed_pattern.id)).to be false
      end

      it 'échoue si un Media::Video utilise encore ce domaine' do
        allowed_pattern = FactoryBot.create(:allowed_pattern, kind: 'url', match_type: 'domain', value: 'youtube.com')
        FactoryBot.create(:media_video, url: 'https://www.youtube.com/watch?v=abc123')

        expect(allowed_pattern.destroy).to be false
        expect(AllowedPattern.exists?(allowed_pattern.id)).to be true
      end
    end

    context 'sur une url exacte (match_type: exact)' do
      it 'échoue si un Media::Form utilise encore cette url exacte' do
        allowed_pattern = FactoryBot.create(:allowed_pattern, kind: 'url', match_type: 'exact', value: 'https://bit.ly/abc123')
        FactoryBot.create(:media_form, url: 'https://bit.ly/abc123')

        expect(allowed_pattern.destroy).to be false
        expect(AllowedPattern.exists?(allowed_pattern.id)).to be true
      end

      it "réussit si aucun Media::Form n'a cette url exacte" do
        allowed_pattern = FactoryBot.create(:allowed_pattern, kind: 'url', match_type: 'exact', value: 'https://bit.ly/inutilise')
        FactoryBot.create(:media_form, url: 'https://bit.ly/abc123')

        expect(allowed_pattern.destroy).to eq(allowed_pattern)
      end
    end
  end

  describe '.url_allowed?' do
    it 'renvoie false si aucun AllowedPattern ne correspond' do
      expect(AllowedPattern.url_allowed?('https://non-whitelisted.example.com/page')).to be false
    end

    it 'renvoie false pour une url blank' do
      expect(AllowedPattern.url_allowed?('')).to be false
      expect(AllowedPattern.url_allowed?(nil)).to be false
    end

    it 'renvoie true si un domaine autorisé correspond' do
      FactoryBot.create(:allowed_pattern, kind: 'url', match_type: 'domain', value: 'partenaire.fr')

      expect(AllowedPattern.url_allowed?('https://www.partenaire.fr/page')).to be true
    end

    it 'renvoie true si une url exacte autorisée correspond' do
      FactoryBot.create(:allowed_pattern, kind: 'url', match_type: 'exact', value: 'https://bit.ly/evenement')

      expect(AllowedPattern.url_allowed?('https://bit.ly/evenement')).to be true
    end

    it 'renvoie false si une url exacte autorisée ne correspond pas exactement (query string différente)' do
      FactoryBot.create(:allowed_pattern, kind: 'url', match_type: 'exact', value: 'https://bit.ly/evenement')

      expect(AllowedPattern.url_allowed?('https://bit.ly/evenement?utm=1')).to be false
    end
  end
end
