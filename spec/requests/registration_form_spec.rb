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
