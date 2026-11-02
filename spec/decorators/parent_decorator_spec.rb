require 'rails_helper'

RSpec.describe ParentDecorator do
  # Étiquette d'adresse : la 1re ligne (nom sur la boîte aux lettres ou raison
  # sociale) est mise en avant, le reste forme le corps de l'adresse.
  describe 'lignes de l’étiquette d’adresse' do
    def parent(**attributs)
      FactoryBot.build(:parent, first_name: 'Sarah', last_name: 'Benali', address: '75 rue Danielle Casanova',
                                address_supplement: nil, postal_code: '93200', city_name: 'Saint-Denis', **attributs).decorate
    end

    context 'pour une livraison à domicile' do
      subject(:etiquette) { parent(book_delivery_location: 'home', letterbox_name: 'Clémence Yobouet') }

      it 'met le nom sur la boîte aux lettres en titre' do
        expect(etiquette.label_heading_line).to eq('CLÉMENCE YOBOUET')
      end

      it 'met la rue puis le code postal et la ville dans le corps' do
        expect(etiquette.label_body_lines).to eq(['75 rue Danielle Casanova', '93200 Saint-Denis'])
      end
    end

    context 'pour une livraison chez un proche' do
      subject(:etiquette) { parent(book_delivery_location: 'relative_home', letterbox_name: 'Famille Durand') }

      it 'met le nom sur la boîte aux lettres en titre' do
        expect(etiquette.label_heading_line).to eq('FAMILLE DURAND')
      end

      it "commence le corps par « A l'attention de » suivi du nom du parent" do
        expect(etiquette.label_body_lines.first).to eq("A l'attention de SARAH BENALI")
      end
    end

    context 'pour une livraison en structure' do
      subject(:etiquette) do
        parent(book_delivery_location: 'association', letterbox_name: nil,
               book_delivery_organisation_name: 'Association Les Lucioles', address_supplement: '1er étage')
      end

      it 'met la raison sociale en titre' do
        expect(etiquette.label_heading_line).to eq('ASSOCIATION LES LUCIOLES')
      end

      it "met l'attention, la rue, le complément puis le code postal et la ville dans le corps" do
        expect(etiquette.label_body_lines).to eq(
          ["A l'attention de SARAH BENALI", '75 rue Danielle Casanova', '1er étage', '93200 Saint-Denis']
        )
      end
    end

    context 'quand le nom sur la boîte aux lettres manque (donnée ancienne)' do
      subject(:etiquette) { parent(book_delivery_location: 'home', letterbox_name: nil) }

      it "n'a pas de titre" do
        expect(etiquette.label_heading_line).to be_nil
      end

      it "garde toute l'adresse dans le corps" do
        expect(etiquette.label_body_lines).to eq(['75 rue Danielle Casanova', '93200 Saint-Denis'])
      end
    end

    it 'découpe les lignes d’étiquette sans en perdre ni en ajouter' do
      etiquette = parent(book_delivery_location: 'relative_home', letterbox_name: 'Famille Durand', address_supplement: 'Bât. B')

      expect([etiquette.label_heading_line, *etiquette.label_body_lines]).to eq(etiquette.label_address_lines)
    end
  end
end
