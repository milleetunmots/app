require "rails_helper"

RSpec.describe "Formulaire d'inscription", type: :request do
  def registration_params(source:, birthdate: nil, birthdate_parts: nil)
    parts = birthdate_parts || { day: birthdate&.day, month: birthdate&.month, year: birthdate&.year }
    {
      child: {
        gender: "f",
        first_name: "Lina",
        last_name: "Martin",
        "birthdate(3i)" => parts[:day].to_s,
        "birthdate(2i)" => parts[:month].to_s,
        "birthdate(1i)" => parts[:year].to_s,
        tag_list: "",
        child_support_attributes: { important_information: "" },
        parent1_attributes: {
          gender: "f",
          first_name: "Sarah",
          last_name: "Martin",
          phone_number: "0612345678",
          book_delivery_location: "home",
          letterbox_name: "Martin",
          address: "12 rue des Lilas",
          postal_code: "93100",
          city_name: "Montreuil"
        },
        parent2_attributes: { first_name: "", last_name: "", phone_number: "" },
        children_source_attributes: { source_id: source.id, details: "", registration_department: source.department }
      }
    }
  end

  before do
    allow_any_instance_of(SpotHit::SendSmsService).to receive(:call).and_return(SpotHit::SendSmsService.new(nil, nil, nil))
  end

  describe "affichage des erreurs serveur" do
    def post_pmi_with(source:)
      params = registration_params(source: source, birthdate: Date.new(2026, 2, 3))
      yield params
      post "/inscription3", params: params
      Capybara.string(response.body)
    end

    it "affiche l'erreur sous le téléphone du parent 1, l'encadré, et pas de pop-up" do
      travel_to Date.new(2026, 11, 12)
      source = FactoryBot.create(:source, channel: "pmi", department: 93)

      page = post_pmi_with(source: source) { |params| params[:child][:parent1_attributes][:phone_number] = "0145678910" }

      expect(Child.count).to eq(0)
      expect(page).to have_css(".child_parent1_phone_number .invalid-feedback")
      expect(page).to have_css("#form-errors", text: "Le formulaire contient des erreurs, elles sont indiquées en rouge.")
      expect(response.body).not_to include("L'inscription de l'enfant a échoué")
    end

    it "affiche l'erreur sous le nom du parent 2" do
      travel_to Date.new(2026, 11, 12)
      source = FactoryBot.create(:source, channel: "pmi", department: 93)

      page = post_pmi_with(source: source) do |params|
        params[:child][:parent2_attributes] = { gender: "m", first_name: "Karim", last_name: "", phone_number: "" }
      end

      expect(page).to have_css(".child_parent2_last_name .invalid-feedback")
      expect(page).to have_css(".child_parent2_phone_number .invalid-feedback")
    end

    it "affiche l'erreur sous le nom de la PMI de livraison" do
      travel_to Date.new(2026, 11, 12)
      source = FactoryBot.create(:source, channel: "pmi", department: 93)

      page = post_pmi_with(source: source) do |params|
        params[:child][:parent1_attributes].merge!(book_delivery_location: "pmi", book_delivery_organisation_name: "", letterbox_name: "")
      end

      expect(page).to have_css("#book_delivery_organisation_name_div .invalid-feedback", text: "doit être rempli")
    end

    it "affiche l'erreur sous la case de consentement des commentaires" do
      travel_to Date.new(2026, 11, 12)
      source = FactoryBot.create(:source, channel: "pmi", department: 93)

      page = post_pmi_with(source: source) do |params|
        params[:child][:child_support_attributes] = { important_information: "Famille bilingue arabe-français", has_important_information_parental_consent: "0" }
      end

      expect(Child.count).to eq(0)
      expect(page).to have_css(".child_child_support_has_important_information_parental_consent .invalid-feedback")
    end

    it "affiche l'erreur de format sous l'email professionnel" do
      travel_to Date.new(2026, 11, 12)
      source = FactoryBot.create(:source, channel: "pmi", department: 93)

      page = post_pmi_with(source: source) do |params|
        params[:want_registration_confirmation_email] = "1"
        params[:registration_confirmation_email] = "s.dupont@cd93"
      end

      expect(Child.count).to eq(0)
      expect(page).to have_css("#registration_confirmation_email_field .invalid-feedback")
    end
  end

  describe "formulaire fermé" do
    it "affiche le message de fermeture avec la nouvelle charte" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("BLOCKED_REGISTRATION_PATHS").and_return("/inscription5")

      get "/inscription5"
      page = Capybara.string(response.body)

      expect(page.find(".charter-page #mots-logo")[:src]).to include("registration/logo-1001mots")
      expect(page.find(".charter-page h1")).to have_text("Les inscriptions sont fermées")
      expect(page.find(".charter-page-body .charter-page-card")).to have_text("contactez-nous à pmi@1001mots.org")
      expect(page).to have_link("pmi@1001mots.org", href: "mailto:pmi@1001mots.org")
      expect(page).not_to have_css("form#new_child")
    end

    it "affiche le message de limite atteinte avec la nouvelle charte" do
      allow_any_instance_of(ChildrenController).to receive(:check_registration_limits) { |controller| controller.instance_variable_set(:@limit_reached, true) }

      get "/inscription3"
      page = Capybara.string(response.body)

      expect(page.find(".charter-page h1")).to have_text("Les inscriptions sont temporairement fermées")
      expect(page.find(".charter-page-body .charter-page-card")).to have_text("Les inscriptions sont limitées")
      expect(page).not_to have_css("form#new_child")
    end
  end

  describe "page de confirmation" do
    it "affiche le logo, le titre, le message dans la zone marine et le bouton pour inscrire un autre enfant" do
      get "/inscription3"

      get "/inscrit"
      page = Capybara.string(response.body)

      expect(page.find(".charter-page #mots-logo")[:src]).to include("registration/logo-1001mots")
      expect(page.find(".charter-page h1")).to have_text("Inscription effectuée avec succès")
      expect(page.find(".charter-page-body .charter-page-card")).to have_text(I18n.t("inscription_success.pro"))
      expect(page.find(".charter-page-body")).to have_link("Inscrire un autre enfant", href: "/inscription3")
      expect(page).to have_link("Retour", href: "/inscription3")
    end

    it "garde le widget de don dans la zone marine pour le formulaire parent" do
      get "/inscription1"

      get "/inscrit"
      page = Capybara.string(response.body)

      expect(page).to have_css(".charter-page-body iframe#helloasso-widget")
      expect(page).not_to have_link("Inscrire un autre enfant")
    end
  end

  describe "visuels du bandeau" do
    {
      "/inscriptioncaf" => ["eymen", "Eymen, 10 mois, promo 2025", "caf-logo"],
      "/inscriptionmsa" => ["eymen", "Eymen, 10 mois, promo 2025", "msa-logo"],
      "/inscription4" => ["eymen", "Eymen, 10 mois, promo 2025", nil],
      "/inscription3" => ["richie", "Richie, 19 mois, promo 2025", nil],
      "/inscriptionpartenaires" => ["richie", "Richie, 19 mois, promo 2025", nil]
    }.each do |path, (photo, caption, partner_logo)|
      it "affiche la photo, la légende, les pilules et le bon logo partenaire sur #{path}" do
        get path
        page = Capybara.string(response.body)

        expect(page.find("#mots-logo")[:src]).to include("registration/logo-1001mots")
        expect(page.find("#registration-photo img")[:src]).to include("registration/#{photo}")
        expect(page.find("#registration-photo figcaption")).to have_text(caption, normalize_ws: true)
        expect(page.all(".registration-pill").map(&:text)).to eq(["Gratuit", "Personnalisé"])
        if partner_logo
          expect(page.find("#partner-logo")[:src]).to include(partner_logo)
        else
          expect(page).not_to have_css("#partner-logo")
        end
      end
    end
  end

  describe "wording" do
    parent_title = "Inscrivez-vous pour recevoir des conseils et des livres gratuits pour votre bébé"
    pro_title = "Inscrivez des familles à l'accompagnement à distance 1001mots"

    {
      "/inscriptioncaf" => [parent_title, "Inscription réservée aux parents ayant reçu un email ou SMS de leur CAF."],
      "/inscriptionmsa" => [parent_title, "Inscription réservée aux parents ayant reçu un email ou SMS de leur MSA."],
      "/inscription4" => [parent_title, nil],
      "/inscription3" => [pro_title, nil],
      "/inscriptionpartenaires" => [pro_title, nil]
    }.each do |path, (title, reserved_line)|
      it "affiche le titre et la mention d'inscription réservée attendus sur #{path}" do
        get path
        page = Capybara.string(response.body)

        expect(page.find("h1").text).to start_with(title)
        if reserved_line
          expect(page.find("#description")).to have_text(reserved_line)
        else
          expect(page.find("#description")).not_to have_text("Inscription réservée")
        end
      end
    end

    ["/inscriptioncaf", "/inscription4", "/inscriptionmsa"].each do |path|
      it "affiche le nouveau bandeau parent sur #{path}" do
        get path
        description = Capybara.string(response.body).find("#description")

        expect(description).to have_text("Pendant 1 an, vous allez recevoir gratuitement un programme adapté à l'âge de votre bébé (entre 0 et 30 mois)")
        expect(description).to have_text("4 appels de spécialistes de la petite enfance, pour discuter et poser vos questions")
        expect(description).to have_text("chaque semaine, des idées d'activités et des conseils par SMS")
        expect(description).to have_text("6 livres pour votre enfant, envoyés dans votre boîte aux lettres")
      end
    end

    ["/inscription3", "/inscriptionpartenaires"].each do |path|
      it "affiche le bandeau PMI sur #{path}" do
        get path
        description = Capybara.string(response.body).find("#description")

        expect(description).to have_text("Programme d'un an, adapté à l'âge de l'enfant (entre 0 et 30 mois). Gratuit et sans engagement pour les familles.")
        expect(description).to have_text("Conseils par SMS 3 fois par semaine.")
        expect(description).to have_text("6 livres adaptés à l'âge de l'enfant et aux thèmes choisis par les parents.")
        expect(description).to have_text("4 appels avec une accompagnante")
        expect(description).not_to have_text("conseillé pour des enfants entre 0 et 3 ans")
      end
    end

    {
      "/inscription3" => true,
      "/inscriptionpartenaires" => true,
      "/inscriptioncaf" => false,
      "/inscription4" => false,
      "/inscriptionmsa" => false
    }.each do |path, with_contact|
      it "#{with_contact ? 'affiche' : "n'affiche pas"} la phrase de contact sur #{path}" do
        get path
        page = Capybara.string(response.body)

        contact = "Si vous rencontrez des difficultés pour remplir le formulaire, vous pouvez nous écrire à pmi@1001mots.org"
        if with_contact
          expect(page).to have_text(contact)
          expect(page).to have_link("pmi@1001mots.org", href: "mailto:pmi@1001mots.org")
        else
          expect(page).not_to have_text(contact)
        end
      end
    end

    it "nomme les téléphones « Téléphone portable » sans toucher le libellé de l'admin" do
      get "/inscription3"
      page = Capybara.string(response.body)

      expect(page.find("label[for='child_parent1_attributes_phone_number']").text).to start_with("Téléphone portable")
      expect(page.find("label[for='child_parent2_attributes_phone_number']").text).to start_with("Téléphone portable")
      expect(Parent.human_attribute_name(:phone_number)).to eq("Téléphone")
    end

    it "garde les titres « Enfant(s) » et « Parent 2 (optionnel) »" do
      get "/inscriptioncaf"
      page = Capybara.string(response.body)

      expect(page).to have_css("h2", text: "Enfant(s)")
      expect(page).to have_css("h3", text: "Parent 2 (optionnel)")
    end
  end

  describe "email professionnel" do
    def post_pmi_with_email(want:, email:)
      source = FactoryBot.create(:source, channel: "pmi", department: 93)
      params = registration_params(source: source, birthdate: Date.new(2026, 2, 3))
      params[:want_registration_confirmation_email] = want
      params[:registration_confirmation_email] = email
      post "/inscription3", params: params
    end

    it "inscrit sans envoyer de mail quand la case est cochée et l'email vide" do
      travel_to Date.new(2026, 11, 12)

      expect { post_pmi_with_email(want: "1", email: "") }.not_to have_enqueued_mail(RegistrationConfirmationMailer, :confirmation)

      child = Child.find_by(first_name: "Lina")
      expect(child).to be_present
      expect(child.children_source_professional_email).to be_nil
    end

    it "n'enregistre ni n'utilise l'email quand la case est décochée" do
      travel_to Date.new(2026, 11, 12)

      expect { post_pmi_with_email(want: "0", email: "s.dupont@cd93.fr") }.not_to have_enqueued_mail(RegistrationConfirmationMailer, :confirmation)

      child = Child.find_by(first_name: "Lina")
      expect(child).to be_present
      expect(child.children_source_professional_email).to be_nil
    end

    it "accepte un email accentué et envoie la confirmation" do
      travel_to Date.new(2026, 11, 12)

      expect { post_pmi_with_email(want: "1", email: "hélène.durand@ville-paris.fr") }.to have_enqueued_mail(RegistrationConfirmationMailer, :confirmation)

      expect(Child.find_by(first_name: "Lina").children_source_professional_email).to eq("hélène.durand@ville-paris.fr")
    end

    it "retire les espaces autour de l'email" do
      travel_to Date.new(2026, 11, 12)

      post_pmi_with_email(want: "1", email: "  s.dupont@cd93.fr  ")

      expect(Child.find_by(first_name: "Lina").children_source_professional_email).to eq("s.dupont@cd93.fr")
    end

    it "n'affiche pas le champ comme obligatoire" do
      get "/inscription3"
      page = Capybara.string(response.body)

      expect(page.find("#registration_confirmation_email")[:required]).to be_nil
      expect(page.find("#registration_confirmation_email")[:type]).not_to eq("email")
    end
  end

  describe "valeurs conservées après une erreur" do
    it "réaffiche toutes les valeurs saisies, même erronées" do
      travel_to Date.new(2026, 11, 12)
      source = FactoryBot.create(:source, channel: "local_partner", department: 93)
      params = registration_params(source: source, birthdate: Date.new(2026, 2, 3))
      params[:child][:child_support_attributes] = { important_information: "Famille bilingue arabe-français", has_important_information_parental_consent: "1" }
      params[:child][:parent1_attributes].merge!(
        phone_number: "0145678910", book_delivery_location: "pmi", book_delivery_organisation_name: "PMI Croix de Chavaux",
        letterbox_name: "", terms_accepted_at: "1"
      )
      params[:child][:parent2_attributes] = { gender: "m", first_name: "Karim", last_name: "", phone_number: "" }
      params[:want_registration_confirmation_email] = "1"
      params[:registration_confirmation_email] = "s.dupont@cd93.fr"

      post "/inscriptionpartenaires", params: params
      page = Capybara.string(response.body)

      expect(Child.count).to eq(0)
      expect(page.find("#child_first_name").value).to eq("Lina")
      expect(page.find("#child_birthdate_3i").value).to eq("3")
      expect(page.find("#child_birthdate_2i").value).to eq("2")
      expect(page.find("#child_birthdate_1i").value).to eq("2026")
      expect(page.find("#child_child_support_attributes_important_information").value).to include("Famille bilingue arabe-français")
      expect(page.find("#child_child_support_attributes_has_important_information_parental_consent")).to be_checked
      expect(page.find("#child_parent1_attributes_phone_number").value).to eq("0145678910")
      expect(page.find("#child_parent2_attributes_gender_m")).to be_checked
      expect(page.find("#child_parent2_attributes_first_name").value).to eq("Karim")
      expect(page.find("#child_parent1_attributes_book_delivery_location").value).to eq("pmi")
      expect(page).to have_css("#address_form_div")
      expect(page.find("#child_parent1_attributes_book_delivery_organisation_name").value).to eq("PMI Croix de Chavaux")
      expect(page.find("#child_parent1_attributes_terms_accepted_at")).to be_checked
      expect(page.find("#want_registration_confirmation_email")).to be_checked
      expect(page.find("#registration_confirmation_email").value).to eq("s.dupont@cd93.fr")
    end

    it "ne présélectionne pas de lieu de livraison à l'ouverture" do
      get "/inscriptionpartenaires"
      page = Capybara.string(response.body)

      expect(page.find("#child_parent1_attributes_book_delivery_location", visible: :all).value).to eq("")
      expect(page).not_to have_css("#address_form_div")
    end
  end

  describe "parent 2" do
    it "ignore un parent 2 dont seul le sexe est coché" do
      travel_to Date.new(2026, 11, 12)
      source = FactoryBot.create(:source, channel: "pmi", department: 93)
      params = registration_params(source: source, birthdate: Date.new(2026, 2, 3))
      params[:child][:parent2_attributes] = { gender: "m", first_name: "", last_name: "", phone_number: "" }

      post "/inscription3", params: params

      child = Child.find_by(first_name: "Lina")
      expect(child).to be_present
      expect(child.parent2).to be_nil
    end
  end

  describe "bornes de la date de naissance" do
    context "sur le formulaire PMI" do
      [
        [Date.new(2024, 5, 13), true],
        [Date.new(2024, 5, 12), false],
        [Date.new(2026, 11, 11), true],
        [Date.new(2026, 11, 12), false]
      ].each do |birthdate, accepted|
        it "#{accepted ? 'accepte' : 'refuse'} un enfant né le #{birthdate.strftime('%d/%m/%Y')}" do
          travel_to Date.new(2026, 11, 12)
          source = FactoryBot.create(:source, channel: "pmi", department: 93)

          post "/inscription3", params: registration_params(source: source, birthdate: birthdate)

          expect(Child.exists?(first_name: "Lina", birthdate: birthdate)).to eq(accepted)
        end
      end
    end

    context "sur le formulaire parent" do
      it "accepte un enfant de 29 mois et 30 jours" do
        travel_to Date.new(2026, 11, 12)
        source = FactoryBot.create(:source)

        post "/inscription1", params: registration_params(source: source, birthdate: Date.new(2024, 5, 13))

        expect(Child.exists?(first_name: "Lina", birthdate: Date.new(2024, 5, 13))).to be true
      end
    end

    context "sans date de naissance" do
      it "réaffiche le formulaire avec une erreur sous la date" do
        travel_to Date.new(2026, 11, 12)
        source = FactoryBot.create(:source, channel: "pmi", department: 93)

        post "/inscription3", params: registration_params(source: source, birthdate_parts: { day: "", month: "", year: "" })

        expect(response).to have_http_status(:ok)
        expect(Child.count).to eq(0)
        expect(response.body).to include("Date de naissance doit être rempli(e)")
        expect(response.body).not_to include("n'est pas une date")
      end
    end

    context "avec une date incomplète" do
      it "refuse l'inscription quand l'année manque" do
        travel_to Date.new(2026, 11, 12)
        source = FactoryBot.create(:source, channel: "pmi", department: 93)

        post "/inscription3", params: registration_params(source: source, birthdate_parts: { day: "3", month: "2", year: "" })

        expect(response).to have_http_status(:ok)
        expect(Child.count).to eq(0)
        expect(response.body).to include("Date de naissance doit être rempli(e)")
      end
    end
  end
end
