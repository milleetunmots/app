require "rails_helper"

RSpec.describe ChildrenController, type: :request do

  describe "#new" do
    it "renders new template" do
      get "/inscription"
      expect(response).to render_template(:new)
    end

    context "when URL is inscription1" do
      before { get "/inscription1" }

      it "renders specific wording" do
        expect(assigns(:child_min_birthdate)).to eq Child.min_birthdate_alt

        expect(response.body).to include I18n.t('inscription_terms_accepted_at_label.parent')
        expect(response.body).to include I18n.t('inscription_registration_source_label.parent')
        expect(response.body).to include I18n.t('inscription_registration_source_details_label.parent')
      end

      it "sets session[:registration_origin]" do
        expect(session[:registration_origin]).to eq 1
      end
    end

    context "when URL is inscription2" do
      before { get "/inscription2" }

      it "renders specific wording" do
        expect(assigns(:child_min_birthdate)).to eq Child.min_birthdate
        expect(assigns(:registration_caf_detail)).to eq I18n.t('inscription_caf.detail')

        expect(response.body).to include I18n.t('inscription_terms_accepted_at_label.parent')
        expect(response.body).to include I18n.t('inscription_registration_source_label.parent')
        expect(response.body).to include I18n.t('inscription_registration_source_details_label.parent')
      end

      it "sets session[:registration_origin]" do
        expect(session[:registration_origin]).to eq 2
      end
    end

    context "when URL is inscription3" do
      before { get "/inscription3" }

      it "renders specific wording" do
        expect(assigns(:child_min_birthdate)).to eq Date.today - 30.months
        expect(assigns(:registration_pmi_detail)).to eq I18n.t('inscription_pmi.detail')

        expect(response.body).to include I18n.t('inscription_terms_accepted_at_label.pro')
        expect(response.body).to include I18n.t('inscription_registration_source_label.pro')
        expect(response.body).to include I18n.t('inscription_registration_source_details_label.pro')
      end

      it "sets session[:registration_origin]" do
        expect(session[:registration_origin]).to eq 3
      end
    end
  end

  describe "#create" do
    context "when params are valid" do
      let(:birthdate) { Faker::Date.between(from: Child.min_birthdate.tomorrow, to: Child.max_birthdate.yesterday) }
      let(:params) {
        {
          child: {
            parent1_attributes: {
              terms_accepted_at: DateTime.now,
              first_name: Faker::Name.first_name,
              last_name: Faker::Name.last_name,
              phone_number: Faker::PhoneNumber.phone_number,
              letterbox_name: Faker::Name.name,
              address: Faker::Address.street_address,
              postal_code: Faker::Address.postcode,
              city_name: Faker::Address.city
            },
            registration_source: Child::REGISTRATION_SOURCES.sample,
            registration_source_details: Faker::Movies::StarWars.planet,
            gender: "",
            first_name: Faker::Name.first_name,
            last_name: Faker::Name.last_name,
            "birthdate(3i)" => birthdate.day.to_s,
            "birthdate(2i)" => birthdate.month.to_s,
            "birthdate(1i)" => birthdate.year.to_s,
            child_support_attributes: { important_information: "" },
            parent2_attributes: {
              first_name: "",
              last_name: "",
              phone_number: ""}
          }
        }
      }


      it "redirects to created page with right sms_url_form" do

      end
    end

    context "when there are errors" do
      it "renders forms" do
      end
    end
  end

  describe "#created" do
    it "renders created template" do
    end

    context "when session[:registration_origin] is not set" do
      it "renders specific wording" do
      end

      it "renders widget" do
      end
    end

    context "when session[:registration_origin] = 1" do
      it "renders specific wording" do
      end

      it "renders widget" do
      end
    end

    context "when session[:registration_origin] = 2" do
      it "renders specific wording" do
      end

      it "does not render widget" do
      end
    end

    context "when session[:registration_origin] = 3" do
      it "renders specific wording" do
      end

      it "does not render widget" do
      end
    end
  end
end
