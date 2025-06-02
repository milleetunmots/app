require 'rails_helper'

RSpec.describe Typeform::UpdateAddressService do
  let(:updating_address_typeform_id) { Faker::Alphanumeric.alpha(number: 6) }
  let(:address_typeform_address_field) { Faker::Alphanumeric.alpha(number: 6) }
  let(:address_typeform_address_supplement_field) { Faker::Alphanumeric.alpha(number: 6) }
  let(:address_typeform_city_name_field) { Faker::Alphanumeric.alpha(number: 6) }
  let(:address_typeform_postal_code_field) { Faker::Alphanumeric.alpha(number: 6) }
  let(:address_typeform_letterbox_name_field) { Faker::Alphanumeric.alpha(number: 6) }

  let(:upstream_address_updating_typeform_id) { Faker::Alphanumeric.alpha(number: 6) }
  let(:upstream_address_updating_typeform_address_field) { Faker::Alphanumeric.alpha(number: 6) }
  let(:upstream_address_updating_typeform_address_supplement_field) { Faker::Alphanumeric.alpha(number: 6) }
  let(:upstream_address_updating_typeform_city_name_field) { Faker::Alphanumeric.alpha(number: 6) }
  let(:upstream_address_updating_typeform_postal_code_field) { Faker::Alphanumeric.alpha(number: 6) }
  let(:upstream_address_updating_typeform_letterbox_name_field) { Faker::Alphanumeric.alpha(number: 6) }

  let(:typeform_city_name) { Faker::Address.city_name }
  let(:typeform_postal_code) { Faker::Address.postcode }
  let(:typeform_address) { Faker::Address.street_address }
  let(:typeform_address_supplement) { Faker::Address.secondary_address }
  let(:typeform_address_letterbox_name) { Faker::Lorem.word }

  let(:mocked_fields_constant) do
    {
      updating_address_typeform_id => {
        address: address_typeform_address_field,
        address_supplement: address_typeform_address_supplement_field,
        city_name: address_typeform_city_name_field,
        postal_code: address_typeform_postal_code_field,
        letterbox_name: address_typeform_letterbox_name_field
      },
      upstream_address_updating_typeform_id => {
        address: upstream_address_updating_typeform_address_field,
        address_supplement: upstream_address_updating_typeform_address_supplement_field,
        city_name: upstream_address_updating_typeform_city_name_field,
        postal_code: upstream_address_updating_typeform_postal_code_field,
        letterbox_name: upstream_address_updating_typeform_letterbox_name_field
      }
    }
  end

  let!(:parent) { FactoryBot.create(:parent, book_delivery_organisation_name: Faker::Company.name, book_delivery_location: Parent::BOOK_DELIVERY_LOCATION.sample) }
  let!(:child) { FactoryBot.create(:child, parent1: parent) }
  let!(:child_support) { child.child_support }

  let!(:form_responses) do
    {
      form_id: '',
      hidden: {
        st: ''
      },
      answers: []
    }
  end

  subject(:service) { Typeform::UpdateAddressService.new(form_responses) }

  before do
    stub_const("Typeform::UpdateAddressService::FIELDS", mocked_fields_constant)
  end

  describe '#call' do
    context 'when parent has not been found' do
      let(:form_responses_with_invalid_parent) do
        form_responses.deep_merge(hidden: { st: "#{parent.security_token}xxx" })
      end
      
      subject(:service_with_invalid_parent) { Typeform::UpdateAddressService.new(form_responses_with_invalid_parent) }

      it 'returns self and contains errors without processing answers' do
        subject.call

        expect(subject.errors).to include({ message: 'parent not found', security_token: "#{parent.security_token}xxx" })
      end
    end

    context 'when current_child has not been found' do
      let(:another_parent) { FactoryBot.create(:parent) }
      let(:form_responses_with_valid_parent) do
        form_responses.deep_merge(hidden: { st: parent.security_token })
      end
      
      subject(:service_with_valid_parent) { Typeform::UpdateAddressService.new(form_responses_with_valid_parent) }

      it 'returns self and contains errors without processing answers' do
        child.update_column(:parent1_id, another_parent.id)

        subject.call

        expect(subject.errors).to include({ message: 'current child not found', parent_id: parent.id })
      end
    end

    context 'when child_support has not been found' do
      let(:form_responses_with_valid_parent) do
        form_responses.deep_merge(hidden: { st: parent.security_token })
      end
      subject(:service_with_valid_parent) { Typeform::UpdateAddressService.new(form_responses_with_valid_parent) }

      it 'returns self and contains errors without processing answers' do
        child.update_column(:child_support_id, nil)

        subject.call

        expect(subject.errors).to include({ message: 'child_support not found', child_id: child.id })
      end
    end

    context "with UPDATING_ADDRESS_TYPEFORM_ID" do
      let(:form_responses_with_answers) do
        form_responses.deep_merge(
          hidden: { st: parent.security_token }, 
          form_id: updating_address_typeform_id, 
          answers: [
            { "type": "text", "text": typeform_city_name, "field": { "id": address_typeform_city_name_field } },
            { "type": "number", "number": typeform_postal_code, "field": { "id": address_typeform_postal_code_field } },
            { "type": "text", "text": typeform_address, "field": { "id": address_typeform_address_field } },
            { "type": "text", "text": typeform_address_supplement, "field": { "id": address_typeform_address_supplement_field } },
            { "type": "text", "text": typeform_address_letterbox_name, "field": { "id": address_typeform_letterbox_name_field } }
          ]
        )
      end

      subject(:service_with_valid_answers) { Typeform::UpdateAddressService.new(form_responses_with_answers) }
      
      it 'updates parent attributes correctly and saves' do
        subject.call

        parent.reload
        expect(parent.address).to eq(typeform_address)
        expect(parent.address_supplement).to eq(typeform_address_supplement)
        expect(parent.city_name).to eq(typeform_city_name)
        expect(parent.postal_code).to eq(typeform_postal_code.to_s)
        expect(parent.letterbox_name).to eq(typeform_address_letterbox_name)
      end

      it 'resets book_delivery_organisation_name and book_delivery_location on parent' do
        expect(parent.book_delivery_organisation_name).not_to be_nil
        expect(parent.book_delivery_location).not_to be_nil

        subject.call

        parent.reload
        expect(parent.book_delivery_organisation_name).to be_nil
        expect(parent.book_delivery_location).to be_nil
      end
    end

    context "with UPSTREAM_ADDRESS_UPDATING_TYPEFORM_ID" do
      let(:form_responses_with_answers) do
        form_responses.deep_merge(
          hidden: { st: parent.security_token }, 
          form_id: upstream_address_updating_typeform_id, 
          answers: [
            { "type": "text", "text": typeform_city_name, "field": { "id": upstream_address_updating_typeform_city_name_field } },
            { "type": "number", "number": typeform_postal_code, "field": { "id": upstream_address_updating_typeform_postal_code_field } },
            { "type": "text", "text": typeform_address, "field": { "id": upstream_address_updating_typeform_address_field } },
            { "type": "text", "text": typeform_address_supplement, "field": { "id": upstream_address_updating_typeform_address_supplement_field } },
            { "type": "text", "text": typeform_address_letterbox_name, "field": { "id": upstream_address_updating_typeform_letterbox_name_field } }
          ]
        )
      end

      subject(:service_with_valid_answers) { Typeform::UpdateAddressService.new(form_responses_with_answers) }
      
      it 'updates parent attributes correctly and saves' do
        subject.call

        parent.reload
        expect(parent.address).to eq(typeform_address)
        expect(parent.address_supplement).to eq(typeform_address_supplement)
        expect(parent.city_name).to eq(typeform_city_name)
        expect(parent.postal_code).to eq(typeform_postal_code.to_s)
        expect(parent.letterbox_name).to eq(typeform_address_letterbox_name)
      end

      it 'resets book_delivery_organisation_name and book_delivery_location on parent' do
        expect(parent.book_delivery_organisation_name).not_to be_nil
        expect(parent.book_delivery_location).not_to be_nil

        subject.call

        parent.reload
        expect(parent.book_delivery_organisation_name).to be_nil
        expect(parent.book_delivery_location).to be_nil
      end
    end

    context 'when parent saves successfully' do
      let(:form_responses) do
        super().deep_merge(
          hidden: { st: parent.security_token }, 
          form_id: upstream_address_updating_typeform_id, 
          answers: [
            { "type": "text", "text": typeform_city_name, "field": { "id": upstream_address_updating_typeform_city_name_field } },
            { "type": "number", "number": typeform_postal_code, "field": { "id": upstream_address_updating_typeform_postal_code_field } },
            { "type": "text", "text": typeform_address, "field": { "id": upstream_address_updating_typeform_address_field } },
            { "type": "text", "text": typeform_address_supplement, "field": { "id": upstream_address_updating_typeform_address_supplement_field } },
            { "type": "text", "text": typeform_address_letterbox_name, "field": { "id": upstream_address_updating_typeform_letterbox_name_field } }
          ]
        )
      end
    
      it 'nils address_suspected_invalid_at on child_support and saves it' do
        child_support.update_column(:address_suspected_invalid_at, Time.zone.now)

        expect(child_support.address_suspected_invalid_at).not_to be_nil

        subject.call

        child_support.reload
        expect(child_support.address_suspected_invalid_at).to be_nil
        end
      end
  end
end