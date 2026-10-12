require 'rails_helper'

RSpec.describe "Admin affichage et filtres de OK pour sollicitation", type: :request do
  let(:libelle) { 'OK pour sollicitation ?' }
  let(:super_admin) { FactoryBot.create(:admin_user, user_role: 'super_admin') }

  let!(:enfant_oui) { FactoryBot.create(:child).tap { |child| child.child_support.update!(ok_for_solicitation: true) } }
  let!(:enfant_non) do
    FactoryBot.create(:child, parent2: FactoryBot.create(:parent)).tap { |child| child.child_support.update!(ok_for_solicitation: false) }
  end
  let!(:enfant_vide) { FactoryBot.create(:child) }

  def page(path, params = {})
    get path, params: params
    Nokogiri::HTML(response.body)
  end

  def ligne_indicateur(document)
    document.css('th').find { |th| th.text.strip == libelle }&.parent
  end

  before { sign_in super_admin }

  describe "affichage de l'indicateur" do
    context "dans la fiche du parent 1" do
      it "affiche la valeur sous le numéro de téléphone" do
        ligne = ligne_indicateur(page("/admin/parents/#{enfant_non.parent1.id}"))

        expect(ligne.at_css('td').text.strip).to eq('Non')
        expect(ligne.previous_element['class']).to include('row-phone_number')
      end
    end

    context "dans la fiche du parent 2" do
      it "affiche la valeur sous le numéro de téléphone" do
        ligne = ligne_indicateur(page("/admin/parents/#{enfant_non.parent2.id}"))

        expect(ligne.at_css('td').text.strip).to eq('Non')
        expect(ligne.previous_element['class']).to include('row-phone_number')
      end
    end

    context "dans la fiche enfant" do
      it "affiche la valeur tout en haut" do
        document = page("/admin/children/#{enfant_oui.id}")
        ligne = ligne_indicateur(document)

        expect(ligne.at_css('td').text.strip).to eq('Oui')
        expect(ligne).to eq(document.at_css('.attributes_table tr'))
      end
    end

    context "dans la fiche de suivi" do
      it "affiche la valeur au-dessus de Infos importantes" do
        ligne = ligne_indicateur(page("/admin/child_supports/#{enfant_non.child_support.id}"))

        expect(ligne.at_css('td').text.strip).to eq('Non')
        expect(ligne.next_element['class']).to include('row-important_information')
      end
    end

    context "quand le menu est vide" do
      it "affiche Vide dans les quatre pages" do
        [
          "/admin/parents/#{enfant_vide.parent1.id}",
          "/admin/children/#{enfant_vide.id}",
          "/admin/child_supports/#{enfant_vide.child_support.id}"
        ].each do |path|
          expect(ligne_indicateur(page(path)).at_css('td').text.strip).to eq('Vide')
        end
      end
    end

    context "quand le menu est renseigné" do
      it "affiche la valeur sous forme d'étiquette, comme les autres booléens" do
        ligne = ligne_indicateur(page("/admin/child_supports/#{enfant_oui.child_support.id}"))

        expect(ligne.at_css('td .status_tag').text.strip).to eq('Oui')
      end
    end

    context "pour la référente de la fiche" do
      it "affiche la valeur dans la fiche du parent de sa famille" do
        referente = FactoryBot.create(:admin_user, user_role: 'caller')
        enfant_non.child_support.update!(supporter: referente)
        sign_in referente

        expect(ligne_indicateur(page("/admin/parents/#{enfant_non.parent1.id}")).at_css('td').text.strip).to eq('Non')
      end
    end

    context "dans la fiche ne montrant jamais le texte sensible" do
      it "n'affiche pas le texte aux pages parent et enfant" do
        enfant_non.child_support.update!(sensitive_information: 'Père placé en foyer')

        get "/admin/parents/#{enfant_non.parent1.id}"
        expect(response.body).not_to include('Père placé en foyer')

        get "/admin/children/#{enfant_non.id}"
        expect(response.body).not_to include('Père placé en foyer')
      end
    end
  end

  describe "filtres" do
    {
      'Oui' => ['yes', :enfant_oui],
      'Non' => ['no', :enfant_non],
      'Vide' => ['empty', :enfant_vide]
    }.each do |nom, (valeur, enfant)|
      context "avec le filtre #{nom}" do
        let(:filtre) { { q: { ok_for_solicitation_is: valeur } } }
        let(:attendu) { send(enfant) }
        let(:autres) { %i[enfant_oui enfant_non enfant_vide].excluding(enfant).map { |autre| send(autre) } }

        it "ne liste que la fiche correspondante dans l'index Suivi" do
          get '/admin/child_supports', params: filtre.merge(scope: 'all')

          expect(response.body).to include("id=\"child_support_#{attendu.child_support.id}\"")
          autres.each { |autre| expect(response.body).not_to include("id=\"child_support_#{autre.child_support.id}\"") }
        end

        it "ne liste que l'enfant correspondant dans l'index Enfant" do
          get '/admin/children', params: filtre

          expect(response.body).to include("id=\"child_#{attendu.id}\"")
          autres.each { |autre| expect(response.body).not_to include("id=\"child_#{autre.id}\"") }
        end

        it "ne liste que le parent correspondant dans l'index Parent" do
          get '/admin/parents', params: filtre

          expect(response.body).to include("id=\"parent_#{attendu.parent1.id}\"")
          autres.each { |autre| expect(response.body).not_to include("id=\"parent_#{autre.parent1.id}\"") }
        end
      end
    end

    %w[/admin/parents /admin/children /admin/child_supports].each do |path|
      it "propose Oui, Non et Vide dans les filtres de #{path}" do
        select = page(path).at_css('select[name="q[ok_for_solicitation_is]"]')

        expect(select.css('option').map { |option| option.text.strip }).to include('Oui', 'Non', 'Vide')
      end
    end

    it "ignore une valeur de filtre inconnue sans erreur" do
      get '/admin/child_supports', params: { q: { ok_for_solicitation_is: 'peut-être' }, scope: 'all' }

      expect(response).to have_http_status(:ok)
    end
  end
end
