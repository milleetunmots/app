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
