require 'rails_helper'

RSpec.describe LabelTextLayout do
  describe '.width_em' do
    it 'additionne les largeurs réelles des glyphes : un W est plus large qu’un i' do
      expect(described_class.width_em('WWWW', 'poppins-regular')).to be > described_class.width_em('iiii', 'poppins-regular')
    end

    it 'compte un caractère inconnu de la police à la largeur du plus large glyphe' do
      inconnu = described_class.width_em('中', 'fredoka-bold')

      expect(inconnu).to be >= described_class.width_em('W', 'fredoka-bold')
    end
  end

  describe '.rows' do
    def rows(text, width_em)
      described_class.rows(text, font: 'poppins-regular', size_pt: 10, width_pt: width_em * 10)
    end

    it 'tient sur une ligne quand le texte est plus étroit que la ligne' do
      expect(rows('75011 Paris', 20)).to eq(1)
    end

    # « Houdhoulai ALI MCHANGAMA - Achim SAID » débordait de l'étiquette : à la longueur
    # près, deux lignes suffisaient, mais coupé aux espaces le texte en prend trois
    it 'coupe aux espaces : un mot qui ne tient plus en fin de ligne passe entier à la suivante' do
      mot = 'Mchangama'
      largeur_mot = described_class.width_em(mot, 'poppins-regular')
      espace = described_class.width_em(' ', 'poppins-regular')
      texte = [mot, mot, mot].join(' ')
      # Assez large pour la longueur totale répartie sur deux lignes, pas pour deux mots par ligne
      largeur = (largeur_mot * 1.6) + espace

      expect(described_class.width_em(texte, 'poppins-regular')).to be <= 2 * largeur
      expect(rows(texte, largeur)).to eq(3)
    end

    it 'coupe aussi après un trait d’union, comme le navigateur' do
      mot = 'Lefebvre'
      largeur = described_class.width_em("#{mot}-", 'poppins-regular') * 1.2

      expect(rows("#{mot}-#{mot}", largeur)).to eq(2)
    end

    it 'coupe n’importe où un mot plus long que la ligne (word-break: break-word)' do
      mot = 'A' * 30
      largeur = described_class.width_em('A' * 10, 'poppins-regular') * 1.01

      expect(rows(mot, largeur)).to eq(3)
    end
  end
end
