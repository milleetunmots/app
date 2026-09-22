require 'rails_helper'

RSpec.describe Book::ImportFromAirtableService do
  # convention du projet : on stubbe les classes Airtables::*, jamais le HTTP.
  # Seul le téléchargement de la couverture, fait par le service lui-même, est
  # stubbé au niveau HTTP.
  let(:cover_url) { 'https://airtable.test/couverture.jpg' }
  let!(:book) { FactoryBot.create(:book, ean: '1234567890', title: 'Petit ours brun') }

  # Les modules sont appariés sur l'airtable_id rapatrié en amont par
  # SupportModule::SyncAirtableIdsService, pas sur le titre
  let!(:support_module) do
    FactoryBot.create(:support_module,
                      name: 'Chanter avec mon enfant',
                      age_ranges: [SupportModule::TWELVE_TO_SEVENTEEN],
                      airtable_id: 'recAAA')
  end

  before do
    stub_request(:get, cover_url)
      .to_return(status: 200, body: File.binread(Dir.glob('db/seed/img/**/*.jpg').first))
  end

  def stub_airtable(module_record_ids)
    airtable_book = {
      'EAN' => book.ean,
      'Titre du livre' => book.title,
      'Photo de la couverture' => [{ 'filename' => 'couverture.jpg', 'url' => cover_url, 'type' => 'image/jpeg' }],
      'Modules' => module_record_ids
    }
    allow(Airtables::Book).to receive(:all).and_return([airtable_book])
  end

  it 'rattache au livre les modules appariés sur Airtable' do
    stub_airtable(['recAAA'])

    service = described_class.new.call

    expect(service.errors[:support_modules]).to be_empty
    expect(book.reload.support_module_ids).to eq([support_module.id])
  end

  it "n'interroge pas Airtable module par module" do
    stub_airtable(['recAAA'])
    allow(Airtables::Module).to receive(:find)

    described_class.new.call

    expect(Airtables::Module).not_to have_received(:find)
  end

  it "signale par un lien Airtable les modules introuvables en base" do
    stub_airtable(['recBBB'])

    service = described_class.new.call

    expect(service.errors[:support_modules])
      .to contain_exactly("Module Airtable introuvable : #{Airtables::Module.record_url('recBBB')}")
    expect(book.reload.support_module_ids).to be_empty
  end

  it "détache les modules d'un livre absent d'Airtable" do
    other_book = FactoryBot.create(:book, ean: '9999999999')
    other_book.support_modules << support_module
    stub_airtable([])

    described_class.new.call

    expect(other_book.reload.support_module_ids).to be_empty
  end
end
