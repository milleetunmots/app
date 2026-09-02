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

    context 'casse' do
      it 'downcase la valeur des patterns domain à la sauvegarde (index unique case-sensitive)' do
        pattern = FactoryBot.create(:allowed_pattern, kind: 'url', match_type: 'domain', value: 'Partenaire.FR')

        expect(pattern.reload.value).to eq('partenaire.fr')
      end

      it 'refuse un doublon domain ne différant que par la casse' do
        FactoryBot.create(:allowed_pattern, kind: 'url', match_type: 'domain', value: 'partenaire.fr')
        duplicate = FactoryBot.build(:allowed_pattern, kind: 'url', match_type: 'domain', value: 'PARTENAIRE.FR')

        expect(duplicate).not_to be_valid
      end

      it 'matche en exact malgré une casse différente sur le schéma et le host' do
        FactoryBot.create(:allowed_pattern, kind: 'url', match_type: 'exact', value: 'HTTPS://Exemple.FR/Page')

        expect(AllowedPattern.url_allowed?('https://exemple.fr/Page')).to be true
      end

      it 'reste sensible à la casse sur le chemin en exact' do
        FactoryBot.create(:allowed_pattern, kind: 'url', match_type: 'exact', value: 'https://exemple.fr/Page')

        expect(AllowedPattern.url_allowed?('https://exemple.fr/page')).to be false
      end
    end

    context 'urls non canoniques (saisies humaines : médiathèque, import Airtable)' do
      before { FactoryBot.create(:allowed_pattern, kind: 'url', match_type: 'domain', value: 'form.typeform.com') }

      it 'autorise une url sans schéma' do
        expect(AllowedPattern.url_allowed?('form.typeform.com/to/abc')).to be true
      end

      it 'autorise un domaine nu' do
        expect(AllowedPattern.url_allowed?('form.typeform.com')).to be true
      end

      it 'autorise une url sans schéma préfixée de www.' do
        expect(AllowedPattern.url_allowed?('www.form.typeform.com/to/abc')).to be true
      end

      it 'autorise une url entourée d\'espaces' do
        expect(AllowedPattern.url_allowed?('  https://form.typeform.com/to/abc  ')).to be true
      end

      it 'autorise une url dont le chemin contient des caractères non ascii' do
        expect(AllowedPattern.url_allowed?('https://form.typeform.com/to/abc?prénom=Zoé')).to be true
      end

      it 'ne relâche pas le contrôle pour autant sur un domaine non autorisé sans schéma' do
        expect(AllowedPattern.url_allowed?('form.typeform.com.attaquant.fr/to/abc')).to be false
      end

      it 'matche un pattern exact depuis une url saisie sans schéma' do
        FactoryBot.create(:allowed_pattern, kind: 'url', match_type: 'exact', value: 'https://bit.ly/evenement')

        expect(AllowedPattern.url_allowed?('bit.ly/evenement')).to be true
      end
    end

    context "domaine de l'app (liens de redirection /r/:id/:code)" do
      around do |example|
        previous = ENV.fetch('DEFAULT_HOSTNAME', nil)
        ENV['DEFAULT_HOSTNAME'] = 'monapp.example.org'
        example.run
        ENV['DEFAULT_HOSTNAME'] = previous
      end

      it 'autorise toujours DEFAULT_HOSTNAME sans pattern en base' do
        expect(AllowedPattern.url_allowed?('https://monapp.example.org/r/12/ab')).to be true
      end

      it "n'autorise pas pour autant un autre domaine" do
        expect(AllowedPattern.url_allowed?('https://autre.example.org/r/12/ab')).to be false
      end
    end
  end

  describe "kind phone_number" do
    it 'canonicalise la valeur saisie, quelle que soit la notation' do
      pattern = FactoryBot.create(:allowed_pattern, kind: 'phone_number', match_type: 'exact', value: '+33 8 10 12 34 56')

      expect(pattern.value).to eq('0810123456')
    end

    it 'refuse le match_type domain, réservé aux URLs' do
      pattern = FactoryBot.build(:allowed_pattern, kind: 'phone_number', match_type: 'domain', value: '0810123456')

      expect(pattern).not_to be_valid
      expect(pattern.errors[:match_type]).to be_present
    end

    it 'refuse une valeur qui ne contient pas assez de chiffres' do
      pattern = FactoryBot.build(:allowed_pattern, kind: 'phone_number', match_type: 'exact', value: 'mon numéro')

      expect(pattern).not_to be_valid
    end

    describe '.phone_allowed?' do
      it 'autorise un numéro whitelisté, saisi dans une autre notation' do
        FactoryBot.create(:allowed_pattern, kind: 'phone_number', match_type: 'exact', value: '+33 810 12 34 56')

        expect(described_class.phone_allowed?('0810123456')).to be true
      end

      it "n'autorise pas un numéro absent de la whitelist" do
        expect(described_class.phone_allowed?('0810123456')).to be false
      end

      it 'est false sur une valeur vide' do
        expect(described_class.phone_allowed?('')).to be false
      end

      it "autorise sans saisie le numéro Aircall d'une accompagnante" do
        FactoryBot.create(:admin_user, aircall_phone_number: '+33810123456')

        expect(described_class.phone_allowed?('0810123456')).to be true
      end

      it "n'autorise pas pour autant un numéro qui n'est celui d'aucune accompagnante" do
        FactoryBot.create(:admin_user, aircall_phone_number: '+33810123456')

        expect(described_class.phone_allowed?('0810999999')).to be false
      end
    end
  end
end
