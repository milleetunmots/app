require 'rails_helper'

RSpec.describe ParentDecorator do
  # Étiquette d'adresse : la 1re ligne (nom sur la boîte aux lettres ou raison
  # sociale) est mise en avant, le reste forme le corps de l'adresse.
  describe 'lignes de l’étiquette d’adresse' do
    def parent(**attributs)
      FactoryBot.build(:parent, first_name: 'Sarah', last_name: 'BENALI', address: '75 rue Danielle Casanova',
                                address_supplement: nil, postal_code: '93200', city_name: 'Saint-Denis', **attributs).decorate
    end

    context 'pour une livraison à domicile' do
      subject(:etiquette) { parent(book_delivery_location: 'home', letterbox_name: 'Clémence Yobouet') }

      it "met le nom sur la boîte aux lettres en titre, tel qu'il a été saisi" do
        expect(etiquette.label_heading_line).to eq('Clémence Yobouet')
      end

      it 'met la rue puis le code postal et la ville dans le corps' do
        expect(etiquette.label_body_lines).to eq(['75 rue Danielle Casanova', '93200 Saint-Denis'])
      end
    end

    context 'pour une livraison chez un proche' do
      subject(:etiquette) { parent(book_delivery_location: 'relative_home', letterbox_name: 'Famille Durand') }

      it "met le nom sur la boîte aux lettres en titre, tel qu'il a été saisi" do
        expect(etiquette.label_heading_line).to eq('Famille Durand')
      end

      it "commence le corps par « A l'attention de » suivi du nom du parent, tel qu'il a été saisi" do
        expect(etiquette.label_body_lines.first).to eq("A l'attention de Sarah BENALI")
      end
    end

    context 'pour une livraison en structure' do
      subject(:etiquette) do
        parent(book_delivery_location: 'association', letterbox_name: nil,
               book_delivery_organisation_name: 'Association Les Lucioles', address_supplement: '1er étage')
      end

      it "met la raison sociale en titre, telle qu'elle a été saisie" do
        expect(etiquette.label_heading_line).to eq('Association Les Lucioles')
      end

      it "met l'attention, la rue, le complément puis le code postal et la ville dans le corps" do
        expect(etiquette.label_body_lines).to eq(
          ["A l'attention de Sarah BENALI", '75 rue Danielle Casanova', '1er étage', '93200 Saint-Denis']
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

    # Le nom de l'enfant est enregistré « Prénom NOM » (NameFormatConcern) : l'étiquette le garde ainsi
    it "adresse une PMI à l'attention de l'enfant, nom tel qu'il est enregistré" do
      pmi = FactoryBot.create(:parent, book_delivery_location: 'pmi', letterbox_name: nil,
                                       book_delivery_organisation_name: 'PMI Franc Moisin')
      FactoryBot.create(:child, parent1: pmi, first_name: 'léa', last_name: 'Martin')

      expect(pmi.decorate.label_address_lines.first(2)).to eq(['PMI Franc Moisin', "A l'attention de Léa MARTIN"])
    end

    it 'garde la casse saisie quand le parent a tout écrit en majuscules' do
      etiquette = parent(book_delivery_location: 'home', letterbox_name: 'CLÉMENCE YOBOUET')

      expect(etiquette.label_heading_line).to eq('CLÉMENCE YOBOUET')
    end
  end

  # Palier de police de l'étiquette : le plus grand dont la hauteur (titre en Fredoka
  # + corps en Poppins) tient dans les 30 mm utiles
  describe '#label_size_class' do
    def parent(**attributs)
      FactoryBot.build(:parent, first_name: 'Sarah', last_name: 'BENALI', address: '75 rue Danielle Casanova',
                                address_supplement: nil, postal_code: '93200', city_name: 'Saint-Denis', **attributs).decorate
    end

    it 'garde le palier maximal pour une adresse à domicile de 3 lignes' do
      expect(parent(book_delivery_location: 'home', letterbox_name: 'Clémence Yobouet').label_size_class).to be_nil
    end

    it 'garde le palier maximal pour un titre sur 2 lignes suivi de 2 lignes de corps' do
      etiquette = parent(book_delivery_location: 'home', letterbox_name: 'Marie-Charlotte Lefebvre-Dupont')

      expect(etiquette.label_size_class).to be_nil
    end

    it 'garde le palier maximal pour un titre et 3 lignes de corps' do
      etiquette = parent(book_delivery_location: 'home', letterbox_name: 'Awa Diallo', address_supplement: 'Bât. B')

      expect(etiquette.label_size_class).to be_nil
    end

    # Le titre, plus grand et en Fredoka, passe à la ligne bien avant le corps (16 caractères au lieu de 25)
    it 'passe au palier réduit quand le titre tient sur 2 lignes et le corps sur 3' do
      etiquette = parent(book_delivery_location: 'home', letterbox_name: 'Marie-Charlotte Lefebvre', address_supplement: 'Bât. B')

      expect(etiquette.label_size_class).to eq('address-content--small')
    end

    it "passe au palier réduit quand l'attention s'ajoute au corps" do
      etiquette = parent(book_delivery_location: 'relative_home', letterbox_name: 'Famille Durand')

      expect(etiquette.label_size_class).to eq('address-content--small')
    end

    it 'passe au plus petit palier pour une structure au nom long avec complément' do
      etiquette = parent(book_delivery_location: 'association', letterbox_name: nil,
                         book_delivery_organisation_name: 'Association Les Lucioles du Quartier Nord',
                         address: '12 avenue du Président Salvador Allende', address_supplement: 'Bâtiment C, 3e étage, porte gauche')

      expect(etiquette.label_size_class).to eq('address-content--tiny')
    end

    it 'reste au plus petit palier quand même celui-ci ne suffit pas' do
      etiquette = parent(book_delivery_location: 'association', letterbox_name: nil,
                         book_delivery_organisation_name: 'Association pour la Promotion de la Lecture en Famille',
                         first_name: 'Marie-Charlotte-Amandine', last_name: 'LEFEBVRE-DUPONT-SAINT-ANDRÉ',
                         address: '12 avenue du Président Salvador Allende prolongée',
                         address_supplement: 'Résidence Les Tilleuls, bâtiment C, 3e étage, porte gauche')

      expect(etiquette.label_size_class).to eq('address-content--tiny')
    end

    it 'compte le corps seul quand le titre manque (donnée ancienne)' do
      etiquette = parent(book_delivery_location: 'home', letterbox_name: nil, address_supplement: 'Bât. B')

      expect(etiquette.label_size_class).to be_nil
    end
  end

  # Fiche de suivi et variable SMS {PARENT_ADDRESS} : l'adresse reste en majuscules,
  # seule l'étiquette garde la casse saisie.
  describe '#full_address' do
    subject(:adresse) do
      FactoryBot.build(:parent, book_delivery_location: 'relative_home', letterbox_name: 'Famille Durand',
                                first_name: 'Sarah', last_name: 'BENALI', address: '75 rue Danielle Casanova',
                                address_supplement: nil, postal_code: '93200', city_name: 'Saint-Denis').decorate
    end

    it 'met le nom et le destinataire en majuscules sur la fiche de suivi' do
      expect(adresse.full_address).to eq(
        "FAMILLE DURAND<br/>A l'attention de SARAH BENALI<br/>75 rue Danielle Casanova<br/>93200 Saint-Denis"
      )
    end

    it 'met le nom et le destinataire en majuscules dans la variable SMS' do
      expect(adresse.full_address(', ')).to eq(
        "FAMILLE DURAND, A l'attention de SARAH BENALI, 75 rue Danielle Casanova, 93200 Saint-Denis"
      )
    end
  end
end
