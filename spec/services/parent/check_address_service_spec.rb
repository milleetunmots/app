require 'rails_helper'

RSpec.describe Parent::CheckAddressService do
  let(:csv_content) do
    [
      ['Prénom', 'Nom', 'Email', 'Boîte aux lettres', 'Adresse', 'Complément', 'Code postal', 'Ville'],
      ['Jean', 'Dupont', 'jean@example.com', 'Apt 42', '123 rue principale', 'Bâtiment A', '75001', 'Paris'],
      ['Marie', 'Martin', 'marie@example.com', '', '45 avenue des fleurs', '', '69001', 'Lyon'],
      ['Pierre', 'Bernard', 'pierre@example.com', 'RDC', '789 boulevard central', '', '13001', 'Marseille']
    ]
  end
  let(:csv_file) { 'tmp/address_check.csv' }
  let(:date) { Time.zone.local(2025, 7, 21, 10, 0) }
  let(:group) { FactoryBot.create(:group, expected_children_number: 0) }

  before do
    allow(Time.zone).to receive(:now).and_return(date)
    CSV.open(csv_file, 'wb') do |csv|
      csv_content.each { |row| csv << row }
    end
  end

  after do
    File.delete(csv_file) if File.exist?(csv_file)
  end

  describe '#call' do
    subject(:service) { Parent::CheckAddressService.new(csv_file) }

    context 'when processing valid CSV data' do
      let!(:parent) do
        FactoryBot.create(:parent,
               letterbox_name: 'Apt 42',
               address: '123 rue principale',
               postal_code: '75001',
               city_name: 'Paris')
      end
      let!(:child) { FactoryBot.create(:child, parent1: parent, group: group, group_status: 'active') }

      it 'updates child_support address_suspected_invalid_at' do
        service.call
        expect(child.child_support.reload.address_suspected_invalid_at).to eq(date)
      end

      it 'sends verification message' do
        program_message_service = instance_double(ProgramMessageService, call: double(errors: []))
        expect(ProgramMessageService).to receive(:new)
                                           .with(
                                             date.strftime('%d-%m-%Y'),
                                             date.strftime('%H:%M'),
                                             ["parent.#{parent.id}"],
                                             "#{described_class::MESSAGE} https://form.typeform.com/to/#{ENV['UPDATING_ADDRESS_TYPEFORM_ID']}#st=#{parent.security_token}"
                                           )
                                           .and_return(program_message_service)

        service.call
      end

      context 'with parent having different delivery location' do
        let!(:parent) do
          FactoryBot.create(:parent,
                 book_delivery_location: 'pmi', book_delivery_organisation_name: 'PMI Machin',
                 letterbox_name: 'Apt 42',
                 address: '123 rue principale',
                 postal_code: '75001',
                 city_name: 'Paris')
        end
        let!(:child) { FactoryBot.create(:child, parent1: parent, group: group, group_status: 'active') }
        it 'skips the parent' do
          service.call
          expect(child.child_support.reload.address_suspected_invalid_at).to be_nil
        end
      end






      end

  end

end
