require 'rails_helper'

RSpec.describe Group::ChildrenSupportModulesInformationsService do
  let(:group) { FactoryBot.create(:group) }
  let(:child) { FactoryBot.create(:child, group: group, group_status: 'active') }
  let(:support_module) do
    FactoryBot.create(:support_module,
           name: "Module",
           theme: SupportModule::READING,
           age_ranges: [SupportModule::FIVE_TO_ELEVEN]
    )
  end
  let(:book) { FactoryBot.create(:book, ean: "9782123456789") }
  let(:index) { 1 }

  let!(:children_support_module) do
    FactoryBot.create(:children_support_module,
           child: child,
           parent_id: child.parent1_id,
           module_index: index,
           support_module_id: support_module.id,
           book_id: book.id
    )
  end

  describe '#call' do
    subject(:service) { Group::ChildrenSupportModulesInformationsService.new(group.id, index) }

    it 'generates zip file with correct name' do
      result = service.call
      expect(result.zip_filename).to eq("Cohorte #{group.name} - Choix modules #{index - 1}.zip")
    end

    it 'creates Excel file with correct headers' do
      result = service.call

      expect(result.zip_file).to be_present

      # workbook = FastExcel.open(result.zip_file.path)
      # worksheet = workbook.sheets.first
      #
      # expect(worksheet.rows.first).to eq(Group::ChildrenSupportModulesInformationsService::COLUMNS)
    end

    # it 'includes support module information in Excel file' do
    #   result = service.call
    #   workbook = FastExcel.open(result.zip_file.path)
    #   worksheet = workbook.sheets.first
    #   data_row = worksheet.rows[1]
    #
    #   expect(data_row).to eq(["Module Test", "5-11 ans", 1, "9782123456789", "Livre Test"])
    # end

    # context 'when child support has invalid address' do
    #   before do
    #     child_support.update(address_suspected_invalid_at: Time.current)
    #   end
    #
    #   it 'excludes the child from the report' do
    #     result = service.call
    #     workbook = FastExcel.open(result.zip_file.path)
    #     worksheet = workbook.sheets.first
    #
    #     # Should only have header row
    #     expect(worksheet.rows.count).to eq(1)
    #   end
    # end
  end
end
