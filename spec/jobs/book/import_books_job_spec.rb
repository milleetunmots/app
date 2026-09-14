require 'rails_helper'

RSpec.describe Book::ImportBooksJob do
  let!(:book) { FactoryBot.create(:book) }
  let!(:support_module) do
    FactoryBot.create(:support_module, book: book, airtable_id: nil,
                      age_ranges: [SupportModule::TWELVE_TO_SEVENTEEN])
  end

  before do
    allow(Rollbar).to receive(:error)
    allow(Airtables::SupportModuleContent).to receive(:all).and_return([
      Airtables::SupportModuleContent.new({ 'titre' => support_module.name, 'Age' => ['12-17 mois'] }, id: 'recCONTENT')
    ])
    allow(Airtables::Book).to receive(:all).and_return([{
      'EAN' => book.ean,
      'Titre du livre' => book.title,
      'Photo de la couverture' => [{ 'filename' => 'cover.jpg' }],
      'Modules' => ['recEXISTING']
    }])
    allow_any_instance_of(Book::ImportFromAirtableService).to receive(:update_cover)
  end

  [Airrecord::Error, Faraday::TimeoutError, Faraday::ConnectionFailed].each do |error_class|
    it "préserve les associations si la première synchronisation échoue avec #{error_class}" do
      allow(Airtables::Module).to receive(:all).and_raise(error_class, 'Indisponible')

      described_class.new.perform

      expect(support_module.reload.book_id).to eq(book.id)
      expect(Airtables::Book).not_to have_received(:all)
      expect(Rollbar).to have_received(:error)
    end
  end

  it 'préserve les associations si Airtable ne renvoie aucun module au premier import' do
    allow(Airtables::Module).to receive(:all).and_return([])

    described_class.new.perform

    expect(support_module.reload.book_id).to eq(book.id)
    expect(Airtables::Book).not_to have_received(:all)
  end

  it 'importe les livres après une synchronisation réussie' do
    record = Airtables::Module.new({ 'titre' => support_module.name, 'age' => '12-17 mois' }, id: 'recEXISTING')
    allow(Airtables::Module).to receive(:all).and_return([record])

    described_class.new.perform

    expect(support_module.reload.airtable_id).to eq('recEXISTING')
    expect(support_module.airtable_content_id).to eq('recCONTENT')
    expect(support_module.book_id).to eq(book.id)
    expect(Airtables::Book).to have_received(:all)
    expect(Rollbar).not_to have_received(:error)
  end

  it 'suspend aussi l’import si un module ne peut pas être apparié' do
    record = Airtables::Module.new({ 'titre' => 'Module inconnu', 'age' => '12-17 mois' }, id: 'recEXISTING')
    allow(Airtables::Module).to receive(:all).and_return([record])

    described_class.new.perform

    expect(support_module.reload.book_id).to eq(book.id)
    expect(Airtables::Book).not_to have_received(:all)
  end

  it 'continue l’import des livres si seule la synchronisation des liens échoue' do
    record = Airtables::Module.new({ 'titre' => support_module.name, 'age' => '12-17 mois' }, id: 'recEXISTING')
    allow(Airtables::Module).to receive(:all).and_return([record])
    allow(Airtables::SupportModuleContent).to receive(:all).and_raise(Faraday::TimeoutError, 'Indisponible')

    described_class.new.perform

    expect(Airtables::Book).to have_received(:all)
    expect(support_module.reload.book_id).to eq(book.id)
    expect(Rollbar).to have_received(:error).with('SupportModule::SyncAirtableContentIdsService', errors: anything)
  end
end
