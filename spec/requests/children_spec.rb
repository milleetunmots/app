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
        expect(response.body).to include I18n.t('source_label.parent')
        expect(response.body).to include I18n.t('source_details_label.parent')
      end

      it "sets session[:registration_origin]" do
        expect(session[:registration_origin]).to eq 1
      end
    end

    context "when URL is inscriptioncaf" do
      before { get "/inscriptioncaf" }

      it "renders specific wording" do
        expect(assigns(:child_min_birthdate)).to eq Child.min_birthdate
        expect(assigns(:registration_caf_detail)).to eq I18n.t('inscription_caf.details')

        expect(response.body).to include I18n.t('inscription_terms_accepted_at_label.parent')
        expect(response.body).to include I18n.t('source_label.caf')
      end

      it "sets session[:registration_origin]" do
        expect(session[:registration_origin]).to eq 2
      end
    end

    context "when URL is inscription3" do
      before { get "/inscription3" }

      it "renders specific wording" do
        expect(assigns(:child_min_birthdate)).to eq Date.today - 30.months

        expect(response.body).to include I18n.t('inscription_terms_accepted_at_label.pro')
        expect(response.body).to include I18n.t('source_label.pmi')
        expect(response.body).to include I18n.t('source_details_label.pro')
      end

      it "sets session[:registration_origin]" do
        expect(session[:registration_origin]).to eq 3
      end
    end
  end

  describe "#create" do
    context "when params are valid" do
      let(:birthdate) { Faker::Date.between(from: Child.min_birthdate.tomorrow, to: Child.max_birthdate.yesterday) }
      let(:source) { FactoryBot.create(:source) }
      let(:params) {
        {
          child: {
            parent1_attributes: {
              terms_accepted_at: Time.zone.now,
              first_name: Faker::Name.first_name,
              last_name: Faker::Name.last_name,
              phone_number: "066802#{Faker::Number.number(digits: 4)}",
              letterbox_name: Faker::Name.name,
              address: Faker::Address.street_address,
              postal_code: Faker::Address.postcode,
              city_name: Faker::Address.city,
              gender: 'f'
            },
            gender: "",
            first_name: Faker::Name.first_name,
            last_name: Faker::Name.last_name,
            "birthdate(3i)" => birthdate.day.to_s,
            "birthdate(2i)" => birthdate.month.to_s,
            "birthdate(1i)" => birthdate.year.to_s,
            tag_list: "",
            child_support_attributes: { important_information: "" },
            parent2_attributes: {
              first_name: "",
              last_name: "",
              phone_number: ""
            },
            children_source_attributes: {
              source_id: source.id,
              details: "",
              registration_department: source.department
            }
          }
        }
      }

      before do
        allow_any_instance_of(SpotHit::SendSmsService).to receive(:call).and_return(SpotHit::SendSmsService.new(nil, nil, nil))
        post "/inscriptioncaf", params: params
      end

      it "redirects to created page with right sms_url_form" do
        expect(response).to redirect_to(created_child_path(sms_url_form: "#{ENV['TYPEFORM_URL']}#child_support_id=#{Child.last.child_support.id}", children_under_four_months: birthdate > 4.months.ago, youngest_child_under_twenty_four_months: birthdate > 24.months.ago))
      end
    end

    context "when there are errors" do
      let(:birthdate) { Faker::Date.between(from: Child.min_birthdate.tomorrow, to: Child.max_birthdate.yesterday) }
      let(:source) { FactoryBot.create(:source) }
      let(:params) {
        {
          child: {
            parent1_attributes: {
              terms_accepted_at: Time.zone.now,
              first_name: nil,
              last_name: nil,
              phone_number: Faker::PhoneNumber.phone_number,
              letterbox_name: Faker::Name.name,
              address: Faker::Address.street_address,
              postal_code: Faker::Address.postcode,
              city_name: Faker::Address.city
            },
            gender: "",
            first_name: Faker::Name.first_name,
            last_name: Faker::Name.last_name,
            "birthdate(3i)" => birthdate.day.to_s,
            "birthdate(2i)" => birthdate.month.to_s,
            "birthdate(1i)" => birthdate.year.to_s,
            tag_list: "",
            child_support_attributes: { important_information: "" },
            parent2_attributes: {
              first_name: "",
              last_name: "",
              phone_number: ""
            },
            children_source_attributes: {
              source_id: source.id,
              details: "",
              registration_department: source.department
            }
          }
        }
      }

      before { post "/inscription", params: params }

      it "renders forms" do
        expect(response).to render_template(:new)
      end
    end
  end

  describe "#created" do
    it "renders created template" do
      get "/inscrit"
      expect(response).to render_template(:created)
    end

    context "when session[:registration_origin] is not set" do
      before { get "/inscrit" }

      it "renders specific wording" do
        expect(response.body).to include I18n.t('inscription_success.with_widget')
      end
    end

    context "when session[:registration_origin] = 1" do
      before do
        ApplicationController.any_instance.stub(:session).and_return({ registration_origin: 1 })
        get "/inscrit"
      end

      it "renders widget" do
        expect(response.body).to include I18n.t('inscription_success.with_widget')
      end
    end

    context "when session[:registration_origin] = 2" do
      before do
        ApplicationController.any_instance.stub(:session).and_return({ registration_origin: 2 })
        get "/inscrit", params: { sms_url_form: nil }
      end

      it "renders specific wording" do
        expect(response.body).to include 'Si vous avez encore 5 minutes'
      end

      it "does not render widget" do
        expect(response.body).not_to include I18n.t('inscription_success.with_widget')
      end
    end

    context "when session[:registration_origin] = 3" do
      before do
        ApplicationController.any_instance.stub(:session).and_return({ registration_origin: 3 })
        get "/inscrit", params: { sms_url_form: nil }
      end
      it "renders specific wording" do
        expect(response.body).to include I18n.t('inscription_success.pro')
      end

      it "does not render widget" do
        expect(response.body).not_to include I18n.t('inscription_success.with_widget')
      end
    end
  end
end
