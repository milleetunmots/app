require 'rails_helper'

RSpec.describe Child::AiRegistrationDetector do
  describe '.ai_sourced?' do
    context 'à partir du tag utm_source' do
      it 'détecte chatgpt.com' do
        expect(described_class.ai_sourced?(tag_list: ['utm_source=chatgpt.com'])).to be true
      end

      it 'détecte claude.ai' do
        expect(described_class.ai_sourced?(tag_list: ['utm_source=claude.ai'])).to be true
      end

      it 'détecte gemini.google.com' do
        expect(described_class.ai_sourced?(tag_list: ['utm_source=gemini.google.com'])).to be true
      end

      it 'ignore la casse' do
        expect(described_class.ai_sourced?(tag_list: ['utm_source=ChatGPT.com'])).to be true
      end

      it 'reconnaît le mot-clé nu, sans domaine' do
        expect(described_class.ai_sourced?(tag_list: ['utm_source=chatgpt'])).to be true
      end

      it 'ne se déclenche pas sur une source légitime' do
        expect(described_class.ai_sourced?(tag_list: ['utm_source=caf01'])).to be false
      end

      it 'ignore les autres tags utm' do
        expect(described_class.ai_sourced?(tag_list: ['utm_medium=chatgpt', 'utm_source=caf01'])).to be false
      end

      it 'retient le tag utm_source parmi plusieurs tags' do
        tags = ['inscription3', 'utm_medium=mail', 'utm_source=chatgpt.com']
        expect(described_class.ai_sourced?(tag_list: tags)).to be true
      end
    end

    context 'repli sur src_url quand le tag est absent' do
      it 'détecte le paramètre utm_source de l’URL' do
        url = 'https://1001mots.org/inscription?utm_source=chatgpt.com&utm_medium=referral'
        expect(described_class.ai_sourced?(src_url: url)).to be true
      end

      it 'ne se déclenche pas sur une source légitime dans l’URL' do
        url = 'https://1001mots.org/inscription?utm_source=caf01'
        expect(described_class.ai_sourced?(src_url: url)).to be false
      end

      it 'renvoie false pour une URL sans utm_source' do
        expect(described_class.ai_sourced?(src_url: 'https://1001mots.org/inscription')).to be false
      end

      it 'renvoie false sans lever pour une URL malformée' do
        expect(described_class.ai_sourced?(src_url: 'pas une url du tout ::')).to be false
      end
    end

    context 'priorité et cas limites' do
      it 'privilégie le tag sur src_url' do
        result = described_class.ai_sourced?(
          tag_list: ['utm_source=caf01'],
          src_url: 'https://1001mots.org/inscription?utm_source=chatgpt.com'
        )
        expect(result).to be false
      end

      it 'renvoie false quand rien n’est fourni' do
        expect(described_class.ai_sourced?).to be false
      end

      it 'renvoie false pour des entrées nil' do
        expect(described_class.ai_sourced?(tag_list: nil, src_url: nil)).to be false
      end

      it 'renvoie false pour un tag utm_source vide' do
        expect(described_class.ai_sourced?(tag_list: ['utm_source='])).to be false
      end

      it 'accepte une TagList d’acts_as_taggable' do
        tag_list = ActsAsTaggableOn::TagList.new('utm_source=chatgpt.com')
        expect(described_class.ai_sourced?(tag_list: tag_list)).to be true
      end
    end
  end
end
