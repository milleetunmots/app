require "rails_helper"

# Parcours complet sur le vrai formulaire : la page est ouverte, remplie champ par champ
# comme le ferait une famille ou une structure, puis envoyée avec « Valider ». Les
# paramètres postés sont donc ceux que produit le HTML rendu, et non des paramètres
# écrits à la main comme dans spec/requests/children_spec.rb.
RSpec.describe "Inscription de bout en bout", type: :system do
  before do
    driven_by :rack_test
    travel_to Date.new(2026, 11, 19)
  end

  def remplir_source(source)
    find("#child_children_source_attributes_source_id").find("option[value='#{source.id}']").select_option
  end

  def remplir_enfant
    first("input[name='child[gender]']").set(true)
    fill_in "child_first_name", with: "Lina"
    fill_in "child_last_name", with: "Martin"
    find("#child_birthdate_3i").find("option[value='14']").select_option
    find("#child_birthdate_2i").find("option[value='3']").select_option
    find("#child_birthdate_1i").find("option[value='2026']").select_option
  end

  def remplir_parent1
    first("input[name='child[parent1_attributes][gender]']").set(true)
    fill_in "child_parent1_attributes_first_name", with: "Sarah"
    fill_in "child_parent1_attributes_last_name", with: "Martin"
    fill_in "child_parent1_attributes_phone_number", with: "0612345678"
  end

  def remplir_adresse
    find("#child_parent1_attributes_letterbox_name", visible: :all).set("Martin")
    find("#address-address", visible: :all).set("75 rue Danielle Casanova")
    find("#address-postal_code", visible: :all).set("93200")
    find("#address-city_name", visible: :all).set("Saint-Denis")
  end

  def accepter_conditions
    find("input[type='checkbox'][name='child[parent1_attributes][terms_accepted_at]']").set(true)
  end

  # rack_test n'exécute pas de JavaScript. Au chargement, new.js retire du formulaire
  # les blocs « Autre enfant » encore masqués (initAddChildBtn, $fields.detach()) : sans
  # cela ils partiraient vides. On fait de même sur le DOM que rack_test soumet ;
  # `garder` blocs sont conservés, comme après autant de clics sur « + Autre enfant ».
  def retirer_freres_et_soeurs_masques(garder: 0)
    page.driver.browser.dom.css(".child-fields-container.hidden .child-fields").drop(garder).each(&:remove)
  end

  def inscrire(path, source, freres_et_soeurs: 0)
    visit path
    retirer_freres_et_soeurs_masques(garder: freres_et_soeurs)
    remplir_source(source)
    remplir_enfant
    remplir_parent1
    yield if block_given?
    remplir_adresse
    accepter_conditions
    expect { click_button "Valider" }.to change(Child, :count).by(1 + freres_et_soeurs)
  end

  def verifier_inscription(source)
    child = Child.order(:created_at).last
    expect(page).to have_current_path(%r{\A/inscrit})
    expect(child.first_name).to eq("Lina")
    expect(child.birthdate).to eq(Date.new(2026, 3, 14))
    expect(child.children_source.source).to eq(source)
    expect(child.parent1).to have_attributes(first_name: "Sarah", last_name: "MARTIN", postal_code: "93200")
    child
  end

  it "fonctionne sur /inscriptioncaf" do
    source = FactoryBot.create(:source, channel: "caf", name: "CAF Seine-Saint-Denis", department: 93)
    inscrire("/inscriptioncaf", source)
    verifier_inscription(source)
  end

  it "fonctionne sur /inscriptionmsa" do
    source = FactoryBot.create(:source, channel: "caf", name: "MSA Île-de-France", department: 93)
    inscrire("/inscriptionmsa", source)
    verifier_inscription(source)
  end

  it "fonctionne sur /inscription4 (BAO)" do
    source = FactoryBot.create(:source, channel: "bao", name: "Mon entourage")
    inscrire("/inscription4", source) do
      find("#child_parent1_attributes_degree_level_at_registration").all("option").reject { |o| o.value.blank? }.first.select_option
      first("input[name='child[parent1_attributes][degree_country_at_registration]']").set(true)
    end
    child = verifier_inscription(source)
    expect(child.parent1.degree_level_at_registration).to be_present
  end

  %w[/inscription3 /inscriptionpartenaires].each do |path|
    describe path do
      let(:source) do
        if path == "/inscription3"
          FactoryBot.create(:source, channel: "pmi", name: "PMI Saint-Denis", department: 93)
        else
          FactoryBot.create(:source, channel: "local_partner", name: "Association du quartier")
        end
      end

      it "fonctionne avec une livraison au domicile" do
        inscrire(path, source) do
          find("#child_parent1_attributes_book_delivery_location").find("option[value='home']").select_option
        end
        child = verifier_inscription(source)
        expect(child.parent1.book_delivery_location).to eq("home")
      end

      it "fonctionne avec l'email de confirmation du professionnel" do
        inscrire(path, source) do
          find("#child_parent1_attributes_book_delivery_location").find("option[value='home']").select_option
          check "want_registration_confirmation_email"
          fill_in "registration_confirmation_email", with: "pro@pmi93.fr"
        end
        child = verifier_inscription(source)
        expect(child.children_source.professional_email).to eq("pro@pmi93.fr")
      end

      it "fonctionne avec une livraison dans une structure" do
        inscrire(path, source) do
          find("#child_parent1_attributes_book_delivery_location").find("option[value='pmi']").select_option
          find("#child_parent1_attributes_book_delivery_organisation_name", visible: :all).set("PMI Saint-Denis")
        end
        child = verifier_inscription(source)
        expect(child.parent1).to have_attributes(book_delivery_location: "pmi", book_delivery_organisation_name: "PMI Saint-Denis")
      end

      it "fonctionne avec un autre enfant ajouté" do
        inscrire(path, source, freres_et_soeurs: 1) do
          find("#child_parent1_attributes_book_delivery_location").find("option[value='home']").select_option
          first("input[name='child[siblings[0]][gender]']").set(true)
          fill_in "child_siblings_0__first_name", with: "Noah"
          fill_in "child_siblings_0__last_name", with: "Martin"
          find("#child_siblings_0_birthdate_3i").find("option[value='2']").select_option
          find("#child_siblings_0_birthdate_2i").find("option[value='6']").select_option
          find("#child_siblings_0_birthdate_1i").find("option[value='2025']").select_option
        end
        child = Child.find_by!(first_name: "Lina")
        expect(child.siblings.pluck(:first_name)).to contain_exactly("Lina", "Noah")
        expect(child.siblings.map { |c| c.children_source.source }.uniq).to eq([source])
      end
    end
  end
end
