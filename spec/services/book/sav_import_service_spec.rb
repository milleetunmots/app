require 'rails_helper'

RSpec.describe Book::SavImportService do
  let_it_be(:group) { FactoryBot.create(:group) }
  let_it_be(:child) { FactoryBot.create(:child, group: group, group_status: 'active') }
  let_it_be(:book) { FactoryBot.create(:book) }
  let_it_be(:not_received_module) do
    FactoryBot.create(:children_support_module, child: child, parent: child.parent1, book: book, book_condition: 'not_received', is_programmed: true)
  end
  let_it_be(:damaged_module) do
    FactoryBot.create(:children_support_module, child: child, parent: child.parent1, book: book, book_condition: 'damaged', is_programmed: true)
  end

  def csv_file_with(content)
    file = Tempfile.new(['sav_import', '.csv'])
    file.write(content)
    file.rewind
    file
  end

  describe '#call' do
    it 'sets book_resent_on when the id and the condition match' do
      csv_file = csv_file_with("05/08/2026,#{not_received_module.id},not_received\n")

      result = described_class.new(csv_file: csv_file).call

      expect(result.errors).to be_empty
      expect(result.matched_count).to eq(1)
      expect(not_received_module.reload.book_resent_on).to eq(Date.new(2026, 8, 5))
    end

    it 'does not update the other book of the same child' do
      csv_file = csv_file_with("05/08/2026,#{not_received_module.id},not_received\n")

      described_class.new(csv_file: csv_file).call

      expect(damaged_module.reload.book_resent_on).to be_nil
    end

    it 'reports an error and skips the row when the id is unknown' do
      csv_file = csv_file_with("05/08/2026,0,not_received\n")

      result = described_class.new(csv_file: csv_file).call

      expect(result.matched_count).to eq(0)
      expect(result.errors.size).to eq(1)
      expect(result.errors.first[0]).to eq(1)
    end

    it 'reports an error when the condition in the csv does not match the current book condition' do
      csv_file = csv_file_with("05/08/2026,#{not_received_module.id},damaged\n")

      result = described_class.new(csv_file: csv_file).call

      expect(result.matched_count).to eq(0)
      expect(result.errors.size).to eq(1)
      expect(not_received_module.reload.book_resent_on).to be_nil
    end

    it 'reports an error when the resend date is invalid' do
      csv_file = csv_file_with("not-a-date,#{not_received_module.id},not_received\n")

      result = described_class.new(csv_file: csv_file).call

      expect(result.matched_count).to eq(0)
      expect(result.errors.size).to eq(1)
    end

    it 'applies valid rows even when other rows fail' do
      csv_file = csv_file_with(
        "05/08/2026,0,non reçu\n" \
        "06/08/2026,#{not_received_module.id},not_received\n"
      )

      result = described_class.new(csv_file: csv_file).call

      expect(result.matched_count).to eq(1)
      expect(result.errors.size).to eq(1)
      expect(not_received_module.reload.book_resent_on).to eq(Date.new(2026, 8, 6))
    end
  end
end
