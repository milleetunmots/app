require 'rails_helper'

RSpec.describe Child::AddEvalTagToChildrenService do
  let(:service) { described_class.new }
  let(:group) { FactoryBot.create(:group, expected_children_number: 0) }
  let!(:child1) { FactoryBot.create(:child, group: group, group_status: 'active') }
  let!(:child2) { FactoryBot.create(:child, group_status: 'waiting') }
  let!(:child3) { FactoryBot.create(:child, group: group, group_status: 'active') }
  let!(:child3_sibling) { FactoryBot.create(:child, parent1: child3.parent1, parent2: child3.parent2) }

  let(:google_sheets_api_service) { instance_double(Google::Apis::SheetsV4::SheetsService) }
  let(:google_sheet_response) { double('response', values: sheet_rows) }
  let(:sheet_rows) { [] }
  let(:sheet_id) { 'fake_sheet_id_for_test' }
  let(:sheet_name) { 'fake_sheet_name_for_test' }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('FAMILY_SUPPORTS_SHEET_ID').and_return(sheet_id)
    allow(ENV).to receive(:[]).with('FAMILY_SUPPORTS_SHEET_NAME').and_return(sheet_name)
    allow(service).to receive(:initialize_sheets) do
      service.instance_variable_set(:@service, google_sheets_api_service)
    end
    allow(google_sheets_api_service).to receive(:get_spreadsheet_values)
                                          .with(sheet_id, sheet_name)
                                          .and_return(google_sheet_response)
  end

  describe '#call' do
    context 'when a child has a "completed" status' do
      let(:sheet_rows) do
        row = Array.new(25)
        row[0] = 'TRUE'
        row[1] = child1.id
        row[6] = 'Actif'
        row[24] = 'Répondu'
        [row]
      end

      it 'adds the "Eval25 - validée" tag to the child' do
        expect { service.call }.to change { child1.reload.tag_list.count }.by(1)
        expect(child1.tag_list).to include('Eval25 - validée')
      end
    end

    context 'when a child has a "refused" status' do
      let(:sheet_rows) do
        row = Array.new(25)
        row[0] = 'TRUE'
        row[1] = child1.id
        row[6] = 'Actif'
        row[24] = 'Refus étude'
        [row]
      end

      it 'adds the "Eval25 - refusée" tag to the child' do
        service.call
        expect(child1.reload.tag_list).to include('Eval25 - refusée')
      end
    end

    context 'when a child has a "three_attempts" status' do
      let(:sheet_rows) do
        row = Array.new(25)
        row[0] = 'TRUE'
        row[1] = child1.id
        row[6] = 'Actif'
        row[24] = 'Non réponse après 3 tentatives KO'
        [row]
      end

      it 'adds the "Eval25 - 3 tentatives" tag to the child' do
        service.call
        expect(child1.reload.tag_list).to include('Eval25 - 3 tentatives')
      end
    end

    context 'when a child has a "pending" status' do
      let(:sheet_rows) do
        row = Array.new(25)
        row[0] = 'TRUE'
        row[1] = child1.id
        row[6] = 'Actif'
        row[24] = 'Rdv pour y répondre'
        [row]
      end

      it 'does not add any tag to the child' do
        expect { service.call }.not_to(change { child1.reload.tag_list.count })
      end
    end

    context 'when a child already has a final evaluation tag' do
      before { child1.tag_list.add('Eval25 - validée') && child1.save }
      let(:sheet_rows) do
        row = Array.new(25)
        row[0] = 'TRUE'
        row[1] = child1.id
        row[6] = 'Actif'
        row[24] = 'Refus étude'
        [row]
      end

      it 'does not add a new tag' do
        expect { service.call }.not_to(change { child1.reload.tag_list.count })
        expect(child1.tag_list).to include('Eval25 - validée')
      end
    end

    context 'when child save fails' do
      let(:sheet_rows) do
        row = Array.new(25)
        row[0] = 'TRUE'
        row[1] = child1.id
        row[6] = 'Actif'
        row[24] = 'Répondu'
        [row]
      end

      before do
        allow(Child).to receive(:find_by).with(id: child1.id.to_i).and_return(child1)
        allow(child1).to receive(:save).and_return(false)
      end

      it 'adds an error to the service' do
        service.call
        expect(service.errors).to include("Impossible d'ajouter de tag à l'enfant avec child_id #{child1.id}")
      end
    end

    context 'with siblings in a control group' do
      let(:sheet_rows) do
        row = Array.new(25)
        row[0] = 'TRUE'
        row[1] = child3.id
        row[6] = 'Témoin'
        row[24] = response_status
        [row]
      end

      context 'with a "Répondu" status' do
        let(:response_status) { 'Répondu' }

        it 'adds "include_in_group" tag to siblings' do
          service.call
          expect(child3_sibling.reload.tag_list).to include('Eval - OK pour inclure dans une cohorte')
        end
      end

      context 'with a "A rappeler plus tard" status' do
        let(:response_status) { 'A rappeler plus tard' }

        it 'adds "exclude_from_group" tag to siblings' do
          service.call
          expect(child3_sibling.reload.tag_list).to include('Eval - ne pas inclure dans une cohorte')
        end
      end
    end
  end
end
