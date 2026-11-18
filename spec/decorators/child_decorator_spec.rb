require 'rails_helper'

RSpec.describe ChildDecorator do
  # Prénom de l'étiquette cadeau : le plus grand palier où il tient sur une ligne
  # dans le cartouche
  describe '#gift_name_size_class' do
    def taille(prenom)
      FactoryBot.build(:child, first_name: prenom).decorate.gift_name_size_class
    end

    it 'garde le palier de la maquette pour un prénom court' do
      expect(taille('Léa')).to be_nil
    end

    it 'garde le palier de la maquette pour un prénom de 12 lettres' do
      expect(taille('Abdourahmane')).to be_nil
    end

    # Mesuré sur les glyphes : à longueur égale, les lettres larges passent plus tôt au palier réduit
    it 'tient compte de la largeur des lettres, pas seulement de leur nombre' do
      expect(taille('Marie-Charlotte')).to be_nil
      expect(taille('Mamadou-Mohamed')).to eq('gift-card-name--tiny')
    end

    it 'passe au palier réduit pour un prénom composé un peu trop large' do
      expect(taille('Mohammed-Amine')).to eq('gift-card-name--small')
    end

    it 'passe au plus petit palier pour un prénom très long' do
      expect(taille('Marie-Charlotte-Amandine')).to eq('gift-card-name--micro')
    end

    it 'reste au plus petit palier quand même celui-ci ne suffit pas' do
      expect(taille('Marie-Charlotte-Amandine-Lou')).to eq('gift-card-name--micro')
    end
  end

  # Crayon « modifier » de la fiche de suivi : une icône seule, sans texte
  describe '#child_link' do
    it 'nomme le lien de modification pour les lecteurs d’écran' do
      child = FactoryBot.create(:child, first_name: 'Lazare', last_name: 'Caron').decorate

      html = Capybara.string(child.child_link(child_support_id: 1))

      expect(html).to have_css('a.js-save-before-leave[aria-label="Modifier Lazare CARON"] i[aria-hidden="true"]')
    end

    it 'porte le genre sur l’icône du lien de la fiche de suivi' do
      child = FactoryBot.create(:child, gender: 'f').decorate

      html = Capybara.string(child.child_link(child_support_id: 1))

      expect(html).to have_css('a.name-link.name-link--girl:not(.rose) i.gender-icon--girl')
    end
  end

  # Prénoms : le lien est en texte, le genre est porté par l'icône (cf. docs/brand_identity.md)
  describe '#admin_link' do
    it 'porte le genre sur l’icône, pas sur le lien' do
      child = FactoryBot.create(:child, gender: 'm', first_name: 'Lazare', last_name: 'Caron').decorate

      html = Capybara.string(child.admin_link(with_icon: true))

      expect(html).to have_css('a.name-link.name-link--boy.kept:not(.blue):not(.rose) i.fas.fa-baby.gender-icon.gender-icon--boy')
    end

    it 'ne met pas de classe de genre quand le genre est inconnu' do
      child = FactoryBot.create(:child, gender: nil).decorate

      html = Capybara.string(child.admin_link(with_icon: true))

      expect(html).to have_css('a.name-link i.gender-icon')
      expect(html).not_to have_css('i.gender-icon--boy, i.gender-icon--girl, a.name-link--boy, a.name-link--girl')
    end
  end

  # Le soulignement est réservé au survol des liens : un parent « à contacter » n'est plus souligné
  describe '#parent1' do
    it 'ne souligne pas le parent à contacter' do
      child = FactoryBot.create(:child, should_contact_parent1: true).decorate

      html = Capybara.string(child.parent1)

      expect(html).to have_css('a.name-link')
      expect(html).not_to have_css('a.txt-underline')
    end
  end

  describe '#gendered_name_with_age' do
    it 'ne colore plus le prénom' do
      child = FactoryBot.create(:child, gender: 'm').decorate

      html = Capybara.string(child.gendered_name_with_age(with_icon: true))

      expect(html).not_to have_css('.txt-blue, .txt-rose')
      expect(html).to have_css('i.gender-icon--boy')
    end
  end
end
