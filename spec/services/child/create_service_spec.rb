require 'rails_helper'

RSpec.describe Child::CreateService do
  let(:birthdate) { Faker::Date.between(from: Child.min_birthdate.tomorrow, to: Child.max_birthdate.yesterday) }
  let(:parent1_attributes) {
    {
      letterbox_name: Faker::Name.name,
      address: Faker::Address.street_address,
      postal_code: Faker::Address.postcode,
      city_name: Faker::Address.city,
      first_name: Faker::Name.first_name,
      last_name: Faker::Name.last_name,
      phone_number: "066802#{Faker::Number.number(digits: 4)}",
      gender: 'f'
    }
  }
  let(:child_min_birthdate) { Child.min_birthdate }

  let(:registration_origin) { nil }
  let(:parent2_attributes) { {} }
  let(:siblings_attributes) { [] }

  let(:attributes) {
    {
      gender: "",
      first_name: Faker::Name.first_name,
      last_name: Faker::Name.last_name,
      "birthdate(3i)" => birthdate.day.to_s,
      "birthdate(2i)" => birthdate.month.to_s,
      "birthdate(1i)" => birthdate.year.to_s
    }
  }

  let(:source) { FactoryBot.create(:source) }

  let(:source_attributes) {
    {
      source_id: source.id,
      details: "",
      registration_department: source.department,
    }
  }

  subject {
    Child::CreateService.new(
      attributes,
      siblings_attributes,
      parent1_attributes,
      parent2_attributes,
      registration_origin,
      source_attributes,
      child_min_birthdate,
    )
  }

  context "when params are valid" do
    context "when registration_origin = 3" do
      let(:registration_origin) { 3 }

      # before { expect_any_instance_of(SpotHit::SendSmsService).to receive(:errors).and_return([]) }

      it "adds 'inscription3' tag" do
        child_count = Child.count
        subject.call
        expect(Child.count).to eq(child_count + 1)
        expect(subject.child.tag_list).to include "inscription3"
      end
    end

    context "when registration_origin = 2" do
      let(:registration_origin) { 2 }

      # before { expect_any_instance_of(SpotHit::SendSmsService).to receive(:errors).and_return([]) }

      it "adds 'inscriptioncaf' tag" do
        child_count = Child.count
        subject.call
        expect(Child.count).to eq(child_count + 1)
        expect(subject.child.tag_list).to include "inscriptioncaf"
      end
    end

    context "when registration_origin is not 2 or 3" do
      let(:registration_origin) { nil }

      it "does not send a sms" do
        child_count = Child.count
        subject.call
        expect(Child.count).to eq(child_count + 1)
        expect_any_instance_of(SpotHit::SendSmsService).not_to receive(:call)
      end
    end

    context "when there are 2 parents" do
      let(:parent2_attributes) {
        {
          first_name: Faker::Name.first_name,
          last_name: Faker::Name.last_name,
          phone_number: "066802#{Faker::Number.number(digits: 4)}",
          gender: 'm'
        }
      }

      it "sets should_contact_parent2 to true" do
        expect(subject.call.child.should_contact_parent2).to be true
      end
    end

    context "when only the second parent is filled" do
      let(:parent2_attributes) {
        {
          first_name: Faker::Name.first_name,
          last_name: Faker::Name.last_name,
          phone_number: "066802#{Faker::Number.number(digits: 4)}",
          gender: 'm'
        }
      }
      let(:parent1_attributes) { {} }

      it "sets the second parent as first parent" do
        expect(subject.call.child.parent1.first_name).to eq parent2_attributes[:first_name]
        expect(subject.call.child.parent1.last_name).to eq parent2_attributes[:last_name]
        expect(subject.call.child.parent2).to be nil
      end
    end

    context "when there are siblings" do
      let(:first_sibling_birthdate) { Faker::Date.between(from: Child.min_birthdate.tomorrow, to: Child.max_birthdate.yesterday) }
      let(:second_sibling_birthdate) { Faker::Date.between(from: Child.min_birthdate.tomorrow, to: Child.max_birthdate.yesterday) }

      let(:parent2_attributes) {
        {
          first_name: Faker::Name.first_name,
          last_name: Faker::Name.last_name,
          phone_number: "066802#{Faker::Number.number(digits: 4)}",
          gender: 'm'
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

      it "creates siblings and add them on same child_support" do
        expect(subject.call.child.child_support.children.count).to eq 3
      end
    end
  end

  context "when params are not valid" do
    context "when child attributes are not valid" do
      let(:attributes) { super().merge(first_name: nil, last_name: nil) }

      it "does not create child" do
        child_count = Child.count
        subject.call
        expect(Child.count).to eq(child_count)
        expect(subject.child).not_to be_valid
      end

      context "when registration_origin = 2" do
        let(:registration_origin) { 2 }

        it "does not send sms" do
          expect_any_instance_of(SpotHit::SendSmsService).not_to receive(:call)
        end
      end

      context "when registration_origin = 3" do
        let(:registration_origin) { 3 }

        it "does not send sms" do
          expect_any_instance_of(SpotHit::SendSmsService).not_to receive(:call)
        end
      end

      context "when parents attributes are not valid" do
        let(:parent1_attributes) { super().merge(first_name: '') }

        it "does not create child" do
          child_count = Child.count
          subject.call
          expect(Child.count).to eq(child_count)
          expect(subject.child).not_to be_valid
        end

        context "when registration_origin = 2" do
          let(:registration_origin) { 2 }

          it "does not send sms" do
            subject.call
            expect_any_instance_of(SpotHit::SendSmsService).not_to receive(:call)
          end
        end
      end

      context "when there are no parents" do
        let(:parent1_attributes) { {} }

        it "does not create child" do
          child_count = Child.count
          subject.call
          expect(Child.count).to eq(child_count)
          expect(subject.child).not_to be_valid
        end

        context "when registration_origin = 2" do
          let(:registration_origin) { 2 }

          it "does not send sms" do
            subject.call
            expect_any_instance_of(SpotHit::SendSmsService).not_to receive(:call)
          end
        end
      end

      context "when siblings are not valid" do
        let(:first_sibling_birthdate) { Faker::Date.between(from: Child.min_birthdate.tomorrow, to: Child.max_birthdate.yesterday) }
        let(:second_sibling_birthdate) { Faker::Date.between(from: Child.min_birthdate.tomorrow, to: Child.max_birthdate.yesterday) }

        let(:siblings_attributes) {
          [
            {
              gender: '',
              first_name: '',
              last_name: '',
              "birthdate(3i)" => first_sibling_birthdate.day.to_s,
              "birthdate(2i)" => first_sibling_birthdate.month.to_s,
              "birthdate(1i)" => first_sibling_birthdate.year.to_s
            },
            {
              gender: '',
              first_name: Faker::Name.first_name,
              last_name: Faker::Name.last_name,
              "birthdate(3i)" => second_sibling_birthdate.day.to_s,
              "birthdate(2i)" => second_sibling_birthdate.month.to_s,
              "birthdate(1i)" => second_sibling_birthdate.year.to_s
            }
          ]
        }

        it "does not create child" do
          child_count = Child.count
          subject.call
          expect(Child.count).to eq(child_count)
          expect(subject.child).not_to be_valid
        end

        context "when registration_origin = 2" do
          let(:registration_origin) { 2 }

          it "does not send sms" do
            subject.call
            expect_any_instance_of(SpotHit::SendSmsService).not_to receive(:call)
          end
        end
      end
    end
  end
end
