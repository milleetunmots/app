require 'rails_helper'

RSpec.describe Aircall::SyncContactsService do
  let(:aircall_id) { '123456789' }
  let(:phone_number) { '+33600000000' }
  let(:parent_first_name) { Faker::Name.first_name }
  let(:parent_last_name) { Faker::Name.last_name }
  let(:child_first_name) { Faker::Name.first_name }

  let(:group) { FactoryBot.create(:group) }

  let(:child_support_edit_link) { "http://test.host/admin/child_supports/x/edit" }

  let(:aircall_datas) do {
    'phone_numbers' => [{ 'id' => 12345, 'value' => phone_number }],
    'first_name' => parent_first_name,
    'last_name' => parent_last_name,
    'company_name' => child_first_name,
    'information' => "Fiche de suivi: #{child_support_edit_link}\nCohorte: #{group.name}\n"
  } end

  let(:parent) { FactoryBot.create(:parent, aircall_id: aircall_id, aircall_datas: aircall_datas, phone_number: phone_number, first_name: parent_first_name, last_name: parent_last_name) }
  let(:child) { FactoryBot.create(:child, group: group, group_status: 'active', parent1: parent, should_contact_parent1: false, first_name: child_first_name) }

  let(:aircall_create_contact_service) { Aircall::CreateContactService.new(parent_id: parent.id) }
  let(:aircall_update_contact_phone_number_service) { Aircall::UpdateContactPhoneNumberService.new(parent_id: parent.id) }
  let(:aircall_update_contact_service) { Aircall::UpdateContactService.new(parent_id: parent.id) }

  let(:aircall_create_contact_service_error) { [{ message: "La création de contact a échoué : Bad Request", status: 400 }] }
  let(:aircall_update_contact_phone_number_service_error) { [{ message: "L'update du numéro de téléphone a échoué : Bad Request", status: 400 }] }
  let(:aircall_update_contact_service_error) { [{ message: "L'update de contact a échoué : Bad Request", status: 400 }] }

  subject { Aircall::SyncContactsService.new }

  before do
    allow(Rails.application.routes.url_helpers).to receive(:edit_admin_child_support_url).with(id: child.child_support_id).and_return(child_support_edit_link)

    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('AIRCALL_ENABLED').and_return(true)

    allow(Aircall::CreateContactService).to receive(:new)
                                        .with(parent_id: parent.id)
                                        .and_return(aircall_create_contact_service)
    allow(aircall_create_contact_service).to receive(:call).and_return(aircall_create_contact_service)

    allow(Aircall::UpdateContactPhoneNumberService).to receive(:new)
                                                    .with(parent_id: parent.id)
                                                    .and_return(aircall_update_contact_phone_number_service)
    allow(aircall_update_contact_phone_number_service).to receive(:call).and_return(aircall_update_contact_phone_number_service)

    allow(Aircall::UpdateContactService).to receive(:new)
                                        .with(parent_id: parent.id)
                                        .and_return(aircall_update_contact_service)
    allow(aircall_update_contact_service).to receive(:call).and_return(aircall_update_contact_service)
  end

  describe '#initialize' do
    it 'initializes errors as an empty array' do
      expect(subject.errors).to eq([])
    end

    it 'initializes created_ids as an empty array' do
      expect(subject.created_ids).to eq([])
    end

    it 'initializes updated_info_ids as an empty array' do
      expect(subject.updated_info_ids).to eq([])
    end

    it 'initializes updated_phone_ids as an empty array' do
      expect(subject.updated_phone_ids).to eq([])
    end
  end

  context 'when AIRCALL_ENABLED is not true' do
    before do
      allow(ENV).to receive(:[]).with('AIRCALL_ENABLED').and_return(nil)
    end

    it 'returns self without processing' do
      expect(Parent).not_to receive(:with_a_child_in_active_group)
      expect(subject.call).to eq(subject)
      expect(subject.created_ids).to be_empty
      expect(subject.errors).to be_empty
      subject.call
    end
  end

  context 'when there are no active children' do 
    before do
      child.update!(group: nil, group_status: 'waiting')
    end

    it 'does not call any Aircall services' do
      expect(Aircall::CreateContactService).not_to receive(:new)
      expect(Aircall::UpdateContactPhoneNumberService).not_to receive(:new)
      expect(Aircall::UpdateContactService).not_to receive(:new)
      subject.call
    end

    it 'returns self with empty arrays' do
      subject.call
      expect(subject.created_ids).to be_empty
      expect(subject.updated_info_ids).to be_empty
      expect(subject.updated_phone_ids).to be_empty
      expect(subject.errors).to be_empty
    end
  end

  context 'for a parent without an aircall_id (creation)' do
    before do
      parent.update!(aircall_id: nil, aircall_datas: nil)
    end

    it 'calls Aircall::CreateContactService' do
      expect(Aircall::CreateContactService).to receive(:new).with(parent_id: parent.id)
      subject.call
    end

    it 'adds parent_id to created_ids on successful creation' do
      subject.call
      expect(subject.created_ids).to include(parent.id)
    end

    it 'adds error to errors array on failed creation' do
      allow(aircall_create_contact_service).to receive(:errors).and_return(aircall_create_contact_service_error)
      subject.call
      expect(subject.errors).to include("Parent #{parent.id}: #{aircall_create_contact_service_error}")
      expect(subject.created_ids).to be_empty
    end
  end

  context 'for a parent with an aircall_id (update)' do
    context 'when aircall_datas is nil' do
      before do
        parent.update!(aircall_datas: nil)
      end

      it 'does not attempt any updates' do
        expect(Aircall::UpdateContactPhoneNumberService).not_to receive(:new)
        expect(Aircall::UpdateContactService).not_to receive(:new)
        subject.call
        expect(subject.updated_phone_ids).to be_empty
        expect(subject.updated_info_ids).to be_empty
      end
    end

    context 'when phone number has changed' do
      before do
        aircall_datas['phone_numbers'].first['value'] = '0700000000'
        parent.update!(aircall_datas: aircall_datas)
      end

      it 'calls Aircall::UpdateContactPhoneNumberService' do
        expect(Aircall::UpdateContactPhoneNumberService).to receive(:new).with(parent_id: parent.id)
        expect(aircall_update_contact_phone_number_service).to receive(:call)
        subject.call
      end

      it 'adds parent_id to updated_phone_ids on successful update' do
        subject.call
        expect(subject.updated_phone_ids).to include(parent.id)
      end

      it 'adds error to errors array on failed phone update' do
        allow(aircall_update_contact_phone_number_service).to receive(:errors).and_return(aircall_update_contact_phone_number_service_error)
        subject.call
        expect(subject.errors).to include("Parent #{parent.id}: #{aircall_update_contact_phone_number_service_error}")
        expect(subject.updated_phone_ids).to be_empty
      end
    end

    context 'when first_name has changed' do
      before do
        aircall_datas['first_name'] = "#{aircall_datas['first_name']}xxxx"
        parent.update!(aircall_datas: aircall_datas)
      end

      it 'calls Aircall::UpdateContactService' do
        expect(Aircall::UpdateContactService).to receive(:new).with(parent_id: parent.id).and_return(aircall_update_contact_service)
        expect(aircall_update_contact_service).to receive(:call)
        subject.call
      end

      it 'adds parent_id to updated_info_ids on successful update' do
        subject.call
        expect(subject.updated_info_ids).to include(parent.id)
      end

      it 'adds error to errors array on failed info update' do
        allow(aircall_update_contact_service).to receive(:errors).and_return(aircall_update_contact_service_error)
        subject.call
        expect(subject.errors).to include("Parent #{parent.id}: #{aircall_update_contact_service_error}")
        expect(subject.updated_info_ids).to be_empty
      end
    end

    context 'when last_name has changed' do
      before do
        aircall_datas['last_name'] = "#{aircall_datas['last_name']}xxxx"
        parent.update!(aircall_datas: aircall_datas)
      end

      it 'calls Aircall::UpdateContactService' do
        expect(Aircall::UpdateContactService).to receive(:new).with(parent_id: parent.id).and_return(aircall_update_contact_service)
        expect(aircall_update_contact_service).to receive(:call)
        subject.call
      end

      it 'adds parent_id to updated_info_ids on successful update' do
        subject.call
        expect(subject.updated_info_ids).to include(parent.id)
      end

      it 'adds error to errors array on failed info update' do
        allow(aircall_update_contact_service).to receive(:errors).and_return(aircall_update_contact_service_error)
        subject.call
        expect(subject.errors).to include("Parent #{parent.id}: #{aircall_update_contact_service_error}")
        expect(subject.updated_info_ids).to be_empty
      end
    end

    context 'when the child first_name has changed' do
      before do
        aircall_datas['company_name'] = "#{aircall_datas['company_name']}xxxx"
        parent.update!(aircall_datas: aircall_datas)
      end

      it 'calls Aircall::UpdateContactService' do
        expect(Aircall::UpdateContactService).to receive(:new).with(parent_id: parent.id).and_return(aircall_update_contact_service)
        expect(aircall_update_contact_service).to receive(:call)
        subject.call
      end

      it 'adds parent_id to updated_info_ids on successful update' do
        subject.call
        expect(subject.updated_info_ids).to include(parent.id)
      end

      it 'adds error to errors array on failed info update' do
        allow(aircall_update_contact_service).to receive(:errors).and_return(aircall_update_contact_service_error)
        subject.call
        expect(subject.errors).to include("Parent #{parent.id}: #{aircall_update_contact_service_error}")
        expect(subject.updated_info_ids).to be_empty
      end
    end

    context 'when the child_support has changed' do
      before do
        aircall_datas['information'] = "Fiche de suivi: http://test.host/admin/child_supports/y/edit\nCohorte: #{group.name}\n"
        parent.update!(aircall_datas: aircall_datas)
      end

      it 'calls Aircall::UpdateContactService' do
        expect(Aircall::UpdateContactService).to receive(:new).with(parent_id: parent.id).and_return(aircall_update_contact_service)
        expect(aircall_update_contact_service).to receive(:call)
        subject.call
      end

      it 'adds parent_id to updated_info_ids on successful update' do
        subject.call
        expect(subject.updated_info_ids).to include(parent.id)
      end

      it 'adds error to errors array on failed info update' do
        allow(aircall_update_contact_service).to receive(:errors).and_return(aircall_update_contact_service_error)
        subject.call
        expect(subject.errors).to include("Parent #{parent.id}: #{aircall_update_contact_service_error}")
        expect(subject.updated_info_ids).to be_empty
      end
    end

    context 'when to group name has changed' do
      before do
        aircall_datas['information'] = "Fiche de suivi: http://test.host/admin/child_supports/2/edit\nCohorte: #{group.name}xxxx\n"
        parent.update!(aircall_datas: aircall_datas)
      end

      it 'calls Aircall::UpdateContactService' do
        expect(Aircall::UpdateContactService).to receive(:new).with(parent_id: parent.id).and_return(aircall_update_contact_service)
        expect(aircall_update_contact_service).to receive(:call)
        subject.call
      end

      it 'adds parent_id to updated_info_ids on successful update' do
        subject.call
        expect(subject.updated_info_ids).to include(parent.id)
      end

      it 'adds error to errors array on failed info update' do
        allow(aircall_update_contact_service).to receive(:errors).and_return(aircall_update_contact_service_error)
        subject.call
        expect(subject.errors).to include("Parent #{parent.id}: #{aircall_update_contact_service_error}")
        expect(subject.updated_info_ids).to be_empty
      end   
    end

    context 'when no data has changed' do
      it 'does not call any update services' do
        expect(Aircall::UpdateContactPhoneNumberService).not_to receive(:new)
        expect(Aircall::UpdateContactService).not_to receive(:new)
        subject.call
        expect(subject.updated_phone_ids).to be_empty
        expect(subject.updated_info_ids).to be_empty
        expect(subject.errors).to be_empty
      end
    end
  end
end
