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
  # + corps en Poppins, lignes coupées aux espaces) tient dans les 29 mm utiles
  describe '#label_size_class' do
    def parent(**attributs)
      FactoryBot.build(:parent, first_name: 'Sarah', last_name: 'BENALI', address: '75 rue Danielle Casanova',
                                address_supplement: nil, postal_code: '93200', city_name: 'Saint-Denis', **attributs).decorate
    end

    it 'garde le palier de la maquette pour une adresse à domicile de 3 lignes' do
      expect(parent(book_delivery_location: 'home', letterbox_name: 'Clémence Yobouet').label_size_class).to be_nil
    end

    it "garde le palier de la maquette quand l'attention s'ajoute au corps" do
      etiquette = parent(book_delivery_location: 'relative_home', letterbox_name: 'Famille Durand')

      expect(etiquette.label_size_class).to be_nil
    end

    it 'garde le palier de la maquette pour un titre composé et 3 lignes de corps' do
      etiquette = parent(book_delivery_location: 'home', letterbox_name: 'Marie-Charlotte Lefebvre', address_supplement: 'Bât. B')

      expect(etiquette.label_size_class).to be_nil
    end

    # Débordait à l'impression : compté en caractères, le titre tenait sur deux lignes ;
    # coupé aux espaces, il en prend une de plus
    it 'compte les lignes coupées aux espaces pour un nom de plusieurs mots' do
      etiquette = parent(book_delivery_location: 'home', letterbox_name: 'Houdhoulai ALI MCHANGAMA - Achim SAID',
                         address: '13 rue Victor Hugo Bâtiment B escalier 4',
                         address_supplement: 'Résidence des Lilas appartement 112',
                         postal_code: '45120', city_name: 'CHALETTE SUR LOING')

      expect(etiquette.label_size_class).to eq('address-content--small')
    end

    it 'passe à un palier plus petit pour une structure au nom long avec complément' do
      etiquette = parent(book_delivery_location: 'association', letterbox_name: nil,
                         book_delivery_organisation_name: 'Association Les Lucioles du Quartier Nord',
                         address: '12 avenue du Président Salvador Allende', address_supplement: 'Bâtiment C, 3e étage, porte gauche')

      expect(etiquette.label_size_class).to eq('address-content--tiny')
    end

    it 'reste au plus petit palier quand même celui-ci ne suffit pas' do
      etiquette = parent(book_delivery_location: 'association', letterbox_name: nil,
                         book_delivery_organisation_name: 'W' * 44, address: 'W' * 44,
                         address_supplement: 'W' * 44, postal_code: '93200', city_name: 'W' * 30)

      expect(etiquette.label_size_class).to eq('address-content--micro')
    end

    it 'compte le corps seul quand le titre manque (donnée ancienne)' do
      etiquette = parent(book_delivery_location: 'home', letterbox_name: nil, address_supplement: 'Bât. B')

      expect(etiquette.label_size_class).to be_nil
    end
  end

  # Le corps est ce que lit le facteur : quand l'étiquette déborde, le titre se resserre
  # avant que le corps ne perde un palier
  describe '#label_heading_class' do
    def parent(**attributs)
      FactoryBot.build(:parent, first_name: 'Sarah', last_name: 'BENALI', address: '75 rue Danielle Casanova',
                                address_supplement: nil, postal_code: '93200', city_name: 'Saint-Denis', **attributs).decorate
    end

    it 'garde le titre à sa taille quand tout tient' do
      expect(parent(book_delivery_location: 'home', letterbox_name: 'Clémence Yobouet').label_heading_class).to be_nil
    end

    it 'resserre le titre plutôt que de réduire le corps quand cela suffit' do
      etiquette = parent(book_delivery_location: 'home', letterbox_name: 'Aissatou Kadiatou Diallo',
                         address: "14 Av. de l'Europe", address_supplement: 'Appartement, 2 ème étage 007 à gauche',
                         postal_code: '57600', city_name: 'Forbach')

      expect(etiquette.label_size_class).to be_nil
      expect(etiquette.label_heading_class).to eq('address-heading--compact')
    end

    it 'préfère un titre à sa taille quand le corps réduit suffit' do
      etiquette = parent(book_delivery_location: 'association', letterbox_name: nil,
                         book_delivery_organisation_name: 'Association Les Lucioles du Quartier Nord',
                         address: '12 avenue du Président Salvador Allende', address_supplement: 'Bâtiment C, 3e étage, porte gauche')

      expect(etiquette.label_size_class).to eq('address-content--tiny')
      expect(etiquette.label_heading_class).to be_nil
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

  # Crayon « modifier » de la fiche de suivi : une icône seule, sans texte
  describe '#admin_link' do
    it 'nomme le lien de modification pour les lecteurs d’écran' do
      parent = FactoryBot.create(:parent, first_name: 'Sarah', last_name: 'Benali').decorate

      html = Capybara.string(parent.admin_link(child_support_id: 1))

      expect(html).to have_css("a.js-save-before-leave[aria-label='Modifier #{parent.name}'] i[aria-hidden='true']")
    end

    # Le lien est en texte, le genre est porté par l'icône (cf. docs/brand_identity.md)
    it 'porte le genre sur l’icône, pas sur le lien' do
      parent = FactoryBot.create(:parent, gender: 'f').decorate

      html = Capybara.string(parent.admin_link(with_icon: true))

      expect(html).to have_css('a.name-link.name-link--girl:not(.rose) i.fas.fa-female.gender-icon.gender-icon--girl')
    end
  end
end
