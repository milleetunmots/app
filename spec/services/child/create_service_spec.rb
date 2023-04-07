require 'rails_helper'

RSpec.describe Child::CreateService do
  let(:birthdate) { Faker::Date.between(from: Child.min_birthdate.tomorrow, to: Child.max_birthdate.yesterday) }
  let(:mother_attributes) {
    {
      first_name: Faker::Name.first_name,
      last_name: Faker::Name.last_name,
      phone_number: Faker::PhoneNumber.phone_number
    }
  }
  let(:parent1_attributes) {
    {
      letterbox_name: Faker::Name.name,
      address: Faker::Address.street_address,
      postal_code: Faker::Address.postcode,
      city_name: Faker::Address.city
    }
  }
  let(:child_min_birthdate) { Child.min_birthdate }

  context "when params are valid" do
    let(:registration_origin) { nil }
    let(:father_attributes) { {} }
    let(:siblings_attributes) { [] }
    let(:attributes) {
      {
        gender: "",
        first_name: Faker::Name.first_name,
        last_name: Faker::Name.last_name,
        registration_source: Child::REGISTRATION_SOURCES.sample,
        registration_source_details: Faker::Movies::StarWars.planet,
        "birthdate(3i)" => birthdate.day.to_s,
        "birthdate(2i)" => birthdate.month.to_s,
        "birthdate(1i)" => birthdate.year.to_s
      }
    }
    subject {
      Child::CreateService.new(
        attributes,
        siblings_attributes,
        parent1_attributes,
        mother_attributes,
        father_attributes,
        registration_origin,
        child_min_birthdate
      ).call
    }
    it "creates a child" do
      expect { subject }.to change(Child, :count).by(1)
    end

    context "when registration_origin = 3" do
      let(:registration_origin) { 3 }
      let(:father_attributes) { {} }
      let(:siblings_attributes) { [] }
      let(:create_service) {
        Child::CreateService.new(
          attributes,
          siblings_attributes,
          parent1_attributes,
          mother_attributes,
          father_attributes,
          registration_origin,
          child_min_birthdate
        ).call
      }

      before { expect_any_instance_of(SpotHit::SendSmsService).to receive(:call) }

      it "adds 'form-pro' tag" do
        expect(create_service.child.tag_list).to include "form-pro"
      end
    end

    context "when registration_origin = 2" do
      let(:registration_origin) { 2 }
      let(:father_attributes) { {} }
      let(:siblings_attributes) { [] }
      let(:create_service) {
        Child::CreateService.new(
          attributes,
          siblings_attributes,
          parent1_attributes,
          mother_attributes,
          father_attributes,
          registration_origin,
          child_min_birthdate
        ).call
      }

      before { expect_any_instance_of(SpotHit::SendSmsService).to receive(:call) }

      it "adds 'form-2' tag" do
        expect(create_service.child.tag_list).to include "form-2"
      end
    end

    context "when registration_origin is not 2 or 3" do
      let(:registration_origin) { nil }
      let(:father_attributes) { {} }
      let(:siblings_attributes) { [] }
      let(:create_service) {
        Child::CreateService.new(
          attributes,
          siblings_attributes,
          parent1_attributes,
          mother_attributes,
          father_attributes,
          registration_origin,
          child_min_birthdate
        ).call
      }

      it "adds 'site' tag" do
        expect(create_service.child.tag_list).to include "site"
      end

    #   it "does not send a sms" do
    #   end
    end

    context "when there are 2 parents" do
      let(:registration_origin) { nil }
      let(:father_attributes) {
        {
          first_name: Faker::Name.first_name,
          last_name: Faker::Name.last_name,
          phone_number: Faker::PhoneNumber.phone_number
        }
      }
      let(:siblings_attributes) { [] }
      let(:create_service) {
        Child::CreateService.new(
          attributes,
          siblings_attributes,
          parent1_attributes,
          mother_attributes,
          father_attributes,
          registration_origin,
          child_min_birthdate
        ).call
      }

      it "sets should_contact_parent2 to true" do
        expect(create_service.child.should_contact_parent2).to be true
      end
    end

    context "when only the second parent is filled" do
      let(:registration_origin) { nil }
      let(:father_attributes) {
        {
          first_name: Faker::Name.first_name,
          last_name: Faker::Name.last_name,
          phone_number: Faker::PhoneNumber.phone_number
        }
      }
      let(:siblings_attributes) { [] }
      let(:create_service) {
        Child::CreateService.new(
          attributes,
          siblings_attributes,
          parent1_attributes,
          {},
          father_attributes,
          registration_origin,
          child_min_birthdate
        ).call
      }

      it "sets the second parent as first parent" do
        expect(create_service.child.parent1.first_name).to eq father_attributes[:first_name]
        expect(create_service.child.parent1.last_name).to eq father_attributes[:last_name]
        expect(create_service.child.parent2).to be nil
      end
    end

    context "when there are siblings" do
      let(:first_sibling_birthdate) { Faker::Date.between(from: Child.min_birthdate.tomorrow, to: Child.max_birthdate.yesterday) }
      let(:second_sibling_birthdate) { Faker::Date.between(from: Child.min_birthdate.tomorrow, to: Child.max_birthdate.yesterday) }

      let(:registration_origin) { nil }
      let(:father_attributes) {
        {
          first_name: Faker::Name.first_name,
          last_name: Faker::Name.last_name,
          phone_number: Faker::PhoneNumber.phone_number
        }
      }
      let(:siblings_attributes) {
        [
          {
            gender: "",
            first_name: Faker::Name.first_name,
            last_name: Faker::Name.last_name,
            "birthdate(3i)" => first_sibling_birthdate.day.to_s,
            "birthdate(2i)" => first_sibling_birthdate.month.to_s,
            "birthdate(1i)" => first_sibling_birthdate.year.to_s
          },
          {
            gender: "",
            first_name: Faker::Name.first_name,
            last_name: Faker::Name.last_name,
            "birthdate(3i)" => second_sibling_birthdate.day.to_s,
            "birthdate(2i)" => second_sibling_birthdate.month.to_s,
            "birthdate(1i)" => second_sibling_birthdate.year.to_s
          }
        ]
      }
      let(:create_service) {
        Child::CreateService.new(
          attributes,
          siblings_attributes,
          parent1_attributes,
          mother_attributes,
          father_attributes,
          registration_origin,
          child_min_birthdate
        ).call
      }

      it "creates siblings and add them on same child_support" do
        expect(create_service.child.child_support.children.count).to eq 3
      end
    end
  end

  context "when params are not valid" do
    let(:registration_origin) { nil }
    let(:father_attributes) { {} }
    let(:siblings_attributes) { [] }
    let(:attributes) {
      {
        gender: "",
        first_name: nil,
        last_name: nil,
        registration_source: Child::REGISTRATION_SOURCES.sample,
        registration_source_details: Faker::Movies::StarWars.planet,
        "birthdate(3i)" => birthdate.day.to_s,
        "birthdate(2i)" => birthdate.month.to_s,
        "birthdate(1i)" => birthdate.year.to_s
      }
     }
     let(:create_service) {
      Child::CreateService.new(
        attributes,
        siblings_attributes,
        parent1_attributes,
        mother_attributes,
        father_attributes,
        registration_origin,
        child_min_birthdate
      ).call
    }

    context "when child attributes are not valid" do
      it "does not create child" do
        expect(create_service.child).not_to be_valid
      end

      # context "when registration_origin = 2" do
      #   it "does not send sms" do
      #   end

      #   context "when registration_source = 'caf' and registration_source_details is blank" do
      #     it "returns validation error" do
      #     end
      #   end
      # end

      # context "when registration_origin = 3" do
      #   it "does not send sms" do
      #   end

      #   context "when registration_source = 'pmi' and pmi_detail is blank" do
      #     it "returns validation error" do
      #     end
      #   end
      # end
    # end

    # context "when parents attributes are not valid" do
    #   it "does not create child" do
    #   end

    #   context "when registration_origin = 2" do
    #     it "does not send sms" do
    #     end
    #   end
    # end

    # context "when there are no parents" do
    #   it "does not create child" do
    #   end

    #   context "when registration_origin = 2" do
    #     it "does not send sms" do
    #     end
    #   end
    # end

    # context "when siblings are not valid" do
    #   it "does not create child" do
    #   end

    #   context "when registration_origin = 2" do
    #     it "does not send sms" do
    #     end
    #   end
    end
  end
end
