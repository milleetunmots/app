require 'rails_helper'

RSpec.describe ChildDecorator do
  # Prénom de l'étiquette cadeau : le plus grand palier où il tient sur une ligne
  # dans le cartouche
  describe '#gift_name_size_class' do
    def taille(prenom)
      FactoryBot.build(:child, first_name: prenom).decorate.gift_name_size_class
    end

    it 'garde le palier maximal pour un prénom court' do
      expect(taille('Léa')).to be_nil
    end

    it "garde le palier maximal jusqu'à 14 caractères" do
      expect(taille('Mohammed-Amine')).to be_nil
    end

    # calibré sur les lettres les plus larges : 15 caractères ne tiennent pas toujours à 13 pt
    it 'passe au palier réduit au-delà de 14 caractères' do
      expect(taille('Mamadou-Mohamed')).to eq('gift-card-name--small')
    end

    it 'passe au palier suivant au-delà de 17 caractères' do
      expect(taille('Marie-Charlotte-Anne')).to eq('gift-card-name--tiny')
    end

    it 'passe au plus petit palier au-delà de 21 caractères' do
      expect(taille('Marie-Charlotte-Amandine')).to eq('gift-card-name--micro')
    end

    it 'reste au plus petit palier quand même celui-ci ne suffit pas' do
      expect(taille('Marie-Charlotte-Amandine-Lou')).to eq('gift-card-name--micro')
    end
  end
end
