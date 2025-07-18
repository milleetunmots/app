require 'rails_helper'

RSpec.describe Group::ChildrenSupportModulesInformationsService do
  let(:group) { FactoryBot.create(:group) }
  let(:child) { FactoryBot.create(:child, group: group, group_status: 'active') }
  let(:support_module) do
    FactoryBot.create(:support_module,
           name: "Module",
           theme: SupportModule::READING,
           age_range: SupportModule::FIVE_TO_ELEVEN
    )
  end
  let(:book) { FactoryBot.create(:book, ean: "9782123456789") }
  let(:index) { 1 }

  let!(:children_support_module) do
    FactoryBot.create(:children_support_module,
           child: child,
           parent_id: child.parent1_id,
           module_index: index,
           support_module: support_module,
           book_ean: book.ean,
           book_title: book.title
    )
  end

  before do
    # Configuration de la date de début pour MODULE_ZERO_FEATURE_START
    allow(ENV).to receive(:[]).with('MODULE_ZERO_FEATURE_START')
                              .and_return((group.started_at + 1.day).to_s)
  end

  describe '#call' do
    subject(:service) { described_class.new(group.id, index) }

    it 'generates zip file with correct name' do
      result = service.call
      expect(result.zip_filename).to eq("Cohorte #{group.name} - Choix modules 0.zip")
    end

    it 'creates Excel file with correct headers' do
      result = service.call
      workbook = FastExcel.open(result.zip_file.path)
      worksheet = workbook.sheets.first

      expect(worksheet.rows.first).to eq(described_class::COLUMNS)
    end

    it 'includes support module information in Excel file' do
      result = service.call
      workbook = FastExcel.open(result.zip_file.path)
      worksheet = workbook.sheets.first
      data_row = worksheet.rows[1]

      expect(data_row).to eq([
                               "Module Test",           # Module
                               "5-11 ans",             # Âges (en supposant que c'est le format retourné par display_age_ranges)
                               1,                      # Effectif
                               "9782123456789",        # EAN
                               "Livre Test"            # Livre
                             ])
    end

    context 'when child support has invalid address' do
      before do
        child_support.update(address_suspected_invalid_at: Time.current)
      end

      it 'excludes the child from the report' do
        result = service.call
        workbook = FastExcel.open(result.zip_file.path)
        worksheet = workbook.sheets.first

        # Should only have header row
        expect(worksheet.rows.count).to eq(1)
      end
    end

    context 'when group started before MODULE_ZERO_FEATURE_START' do
      before do
        group.update!(started_at: 1.year.ago)
        allow(ENV).to receive(:[]).with('MODULE_ZERO_FEATURE_START')
                                  .and_return(Time.current.to_s)
      end

      it 'uses the correct module number in filename' do
        result = service.call
        expect(result.zip_filename).to eq("Cohorte #{group.name} - Choix modules 1.zip")
      end
    end
  end
end
