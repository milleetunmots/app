require 'rails_helper'

RSpec.describe Parent::CheckAddressService do
  let(:csv_content) do
    [
      ['Date', 'Titre de livre', 'Prenom', 'Nom', 'Adresse', 'Complément', 'code postal', 'Ville'],
      ['05/06/2025', 'La ferme', 'Jean', 'Martin', '123 rue principale', 'Apt 42', '75001', 'Mantes la jolie'],
      ['05/06/2025', 'La ferme', 'Mathieu', 'Niel', '45, avenue-des fleurs!', '', '69001', 'Lyon'],
      ['05/06/2025', 'La ferme', 'Désiré', 'Doué', '789 boulevard central', 'RDC', '.03001', 'Marseille']
    ]
  end
  let(:csv_file) { 'tmp/address_check.csv' }
  let(:date) { Time.zone.local(2025, 7, 21, 10, 0) }
  let(:group) { FactoryBot.create(:group, expected_children_number: 0) }
  let!(:parent) do
    FactoryBot.create(:parent,
                      letterbox_name: 'Martin',
                      address: '123 rue principale',
                      postal_code: '75001',
                      city_name: 'Mantes-la-jolie')
  end
  let!(:child) { FactoryBot.create(:child, parent1: parent, group: group, group_status: 'active') }
  let!(:child_support) { child.child_support }

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

    context 'for every line in the csv file, find the parent who matches with the information on the line' do
      let!(:parent2) do
        FactoryBot.create(:parent,
                          letterbox_name: 'Niel',
                          address: '45 avenue des fleurs',
                          postal_code: '69001',
                          city_name: 'Lyon')
      end
      let!(:child2) { FactoryBot.create(:child, parent1: parent2, group: group, group_status: 'active') }
      let!(:child_support2) { child2.child_support }
      let!(:parent3) do
        FactoryBot.create(:parent,
                          letterbox_name: 'Doué',
                          address: '789 boulevard central',
                          postal_code: '03001',
                          city_name: 'Marseille')
      end
      let!(:child3) { FactoryBot.create(:child, parent1: parent3, group: group, group_status: 'active') }
      let!(:child_support3) { child3.child_support }
      it 'ignores commas, accents, and special characters in the address when matching the parent' do
        service.call
        expect(child2.child_support.reload.address_suspected_invalid_at).to eq(date)
      end

      it 'ignores points in the postal code when matching the parent' do
        service.call
        expect(child3.child_support.reload.address_suspected_invalid_at).to eq(date)
      end

      it 'ignores dash in the city name code when matching the parent' do
        service.call
        expect(child.child_support.reload.address_suspected_invalid_at).to eq(date)
      end
    end

    context 'when processing valid CSV data' do
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
        it 'skips the parent' do
          parent.update_columns(book_delivery_location: 'pmi', book_delivery_organisation_name: 'PMI Machin')
          service.call
          expect(child.child_support.reload.address_suspected_invalid_at).to be_nil
        end
      end

      context 'with already suspected invalid address' do
        it 'skips updating the child support' do
          child_support.update_column(:address_suspected_invalid_at, date.prev_day)
          old_suspected_date = child_support.address_suspected_invalid_at
          service.call
          expect(child.child_support.reload.address_suspected_invalid_at).to eq(old_suspected_date)
        end
      end

      context 'with parent missing child support' do
        it 'adds error message' do
          child.update_column(:child_support_id, nil)
          service.call
          expect(service.errors).to include("Aucune fiche de suivi n'est lié à #{parent.first_name} #{parent.last_name}")
        end
      end

      context 'with message service errors' do
        it 'captures message service errors' do
          allow_any_instance_of(ProgramMessageService).to receive(:call).and_return(double(errors: ['SMS failed']))
          service.call
          expect(service.errors).to include("Address Verification message not sent to #{parent.first_name} #{parent.last_name} : SMS failed")
        end
      end
    end
  end
end
