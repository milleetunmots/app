require 'rails_helper'

RSpec.describe 'Admin génération des étiquettes depuis la page Enfants', type: :request do
  autorises = %w[super_admin contributor reader]
  refuses = %w[caller animator]

  let(:tag_mecenat) { 'collecte et envoi de livres mecenes' }

  def enfant(prenom, nom_boite_aux_lettres)
    parent = FactoryBot.create(:parent, book_delivery_location: 'home', letterbox_name: nom_boite_aux_lettres,
                                        address: '75 rue Danielle Casanova', postal_code: '93200', city_name: 'Saint-Denis')
    FactoryBot.create(:child, parent1: parent, first_name: prenom)
  end

  let!(:enfants) do
    [
      enfant('Julian', 'Clémence Yobouet'),
      enfant('Léa', 'Sarah Martin'),
      enfant('Noah', 'Karim Benali'),
      enfant('Inès', 'Awa Diallo')
    ]
  end

  # `debug` rend la planche en HTML (show_as_html) au lieu d'appeler wkhtmltopdf
  def generer(action, selection = enfants)
    post '/admin/children/batch_action', params: {
      batch_action: action,
      collection_selection: selection.map(&:id),
      debug: ''
    }, headers: { 'HTTP_REFERER' => '/admin/children' }
  end

  def planche
    Nokogiri::HTML(response.body).at_css('.addresses')
  end

  def cases
    planche.element_children.map { |bloc| [bloc['class'], bloc.text.squish] }
  end

  def fiches_taguees
    enfants.map { |e| e.child_support.reload }.select { |fiche| fiche.tag_list.include?(tag_mecenat) }
  end

  %w[addresses_pdf mecenat_addresses_pdf].each do |action|
    describe "action #{action}" do
      context 'pour un administrateur' do
        before do
          sign_in FactoryBot.create(:admin_user, user_role: 'super_admin')
          generer(action)
        end

        it 'remplit la planche par rangées de 3 : adresses puis cadeaux, cases vides en fin de rangée' do
          expect(response).to have_http_status(:ok)
          expect(cases.map(&:first)).to eq(
            %w[address address address gift-card gift-card gift-card address address address gift-card]
          )
          expect(cases[7].last).to be_empty
          expect(cases[8].last).to be_empty
        end

        it "met le nom sur la boîte aux lettres en titre de l'étiquette d'adresse, tel qu'il a été saisi" do
          titres = planche.css('.address-heading').map { |titre| titre.text.squish }

          expect(titres).to eq(['Clémence Yobouet', 'Sarah Martin', 'Karim Benali', 'Awa Diallo'])
        end

        it "met la rue puis le code postal et la ville dans le corps de l'étiquette, une ligne chacun" do
          lignes_julian = planche.at_css('.address-body').inner_html.split(%r{<br\s*/?>}).map(&:squish)

          expect(lignes_julian).to eq(['75 rue Danielle Casanova', '93200 Saint-Denis'])
        end

        it "affiche « Un livre pour » puis le prénom de l'enfant sur la ligne suivante" do
          cadeaux = planche.css('.gift-card').map do |carte|
            [carte.at_css('.gift-card-intro').text.squish, carte.at_css('.gift-card-name').text.squish]
          end

          expect(cadeaux).to eq([['Un livre pour', 'Julian'], ['Un livre pour', 'Léa'], ['Un livre pour', 'Noah'], ['Un livre pour', 'Inès']])
        end

        it 'applique au prénom le palier de police calculé pour sa longueur' do
          prenoms = planche.css('.gift-card-name').pluck('class')

          expect(prenoms).to all(eq('gift-card-name'))
        end

        it "n'affiche plus l'ancien texte « Un cadeau pour … ! »" do
          textes = planche.css('.gift-card').map { |carte| carte.text.squish }

          expect(textes).to all(satisfy { |texte| texte.exclude?('Un cadeau pour') && texte.exclude?('!') })
        end

        it "affiche l'icône cadeau de la nouvelle charte, sous le cartouche" do
          carte = planche.at_css('.gift-card')

          expect(carte.at_css('img.gift-card-icon')['src']).to include('gift-1001mots')
          # ordre d'empilement : l'icône, puis l'ombre, puis le cartouche par-dessus
          expect(carte.element_children.pluck('class')).to eq(%w[gift-card-icon gift-card-shadow gift-card-label])
        end
      end

      autorises.each do |role|
        it "génère la planche pour un #{role}" do
          sign_in FactoryBot.create(:admin_user, user_role: role)

          generer(action)

          expect(response).to have_http_status(:ok)
          expect(planche).to be_present
        end
      end

      refuses.each do |role|
        context "avec une requête forgée d'un #{role}" do
          before do
            sign_in FactoryBot.create(:admin_user, user_role: role)
            generer(action)
          end

          it 'refuse et renvoie vers la page Enfants' do
            expect(response).to redirect_to('/admin/children')
            expect(flash[:alert]).to be_present
          end

          it 'ne tague aucune fiche de suivi' do
            expect(fiches_taguees).to be_empty
          end
        end
      end
    end
  end

  describe 'étiquettes mécénat' do
    before do
      sign_in FactoryBot.create(:admin_user, user_role: 'contributor')
      generer('mecenat_addresses_pdf')
    end

    it 'tague les fiches de suivi pour les exclure des prochaines collectes' do
      expect(fiches_taguees).to match_array(enfants.map(&:child_support))
    end

    it 'garde ce tag invisible des accompagnantes et des animatrices' do
      expect(Tag.find_by(name: tag_mecenat).is_visible_by_callers_and_animators).to be(false)
    end
  end

  describe 'étiquettes standard' do
    it 'ne tague aucune fiche de suivi' do
      sign_in FactoryBot.create(:admin_user, user_role: 'contributor')

      generer('addresses_pdf')

      expect(fiches_taguees).to be_empty
    end
  end
end
