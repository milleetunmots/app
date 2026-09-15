require 'rails_helper'

RSpec.describe SupportModule::SyncAirtableContentIdsService do
  let!(:support_module) do
    FactoryBot.create(:support_module, name: 'Chanter avec bébé',
                      age_ranges: [SupportModule::FOUR_TO_ELEVEN], airtable_id: 'recBOOK')
  end

  def record(id: 'recCONTENT', title: support_module.name)
    Airtables::SupportModuleContent.new({ 'titre' => title, 'Age' => ['04-11 mois'] }, id: id)
  end

  before { allow(Airtables::SupportModuleContent).to receive(:all).and_return([record]) }

  it 'stocke le dossier séparément de l’identifiant utilisé pour les livres' do
    service = described_class.new.call
    expect(service.errors).to be_empty
    expect(support_module.reload.airtable_content_id).to eq('recCONTENT')
    expect(support_module.airtable_id).to eq('recBOOK')
    expect(Airtables::SupportModuleContent).to have_received(:all).with(fields: ['titre', 'Age', 'SMS envoyés']).once
  end

  it 'charge tous les dossiers une seule fois même avec plusieurs modules' do
    second_module = FactoryBot.create(:support_module, name: 'Jouer', age_ranges: [SupportModule::FOUR_TO_ELEVEN])
    allow(Airtables::SupportModuleContent).to receive(:all).and_return([record, record(id: 'recTWO', title: 'Jouer')])
    described_class.new.call
    expect(second_module.reload.airtable_content_id).to eq('recTWO')
    expect(Airtables::SupportModuleContent).to have_received(:all).once
  end

  it 'conserve un lien connu malgré un renommage du dossier, sans nouvelle écriture' do
    support_module.update!(airtable_content_id: 'recCONTENT')
    allow(Airtables::SupportModuleContent).to receive(:all).and_return([record(title: 'Nouveau titre')])
    expect { described_class.new.call }.not_to change { support_module.reload.updated_at }
    expect(support_module.airtable_content_id).to eq('recCONTENT')
  end

  it 'remplace un dossier supprimé par son nouvel équivalent' do
    support_module.update!(airtable_content_id: 'recOLD')
    described_class.new.call
    expect(support_module.reload.airtable_content_id).to eq('recCONTENT')
  end

  it 'retire un lien supprimé seulement après récupération complète des dossiers' do
    support_module.update!(airtable_content_id: 'recOLD')
    allow(Airtables::SupportModuleContent).to receive(:all).and_return([record(title: 'Autre module')])
    described_class.new.call
    expect(support_module.reload.airtable_content_id).to be_nil
  end

  it 'conserve les liens si la liste reçue est vide' do
    support_module.update!(airtable_content_id: 'recCONTENT')
    allow(Airtables::SupportModuleContent).to receive(:all).and_return([])
    expect(described_class.new.call.errors).not_to be_empty
    expect(support_module.reload.airtable_content_id).to eq('recCONTENT')
  end

  [Airrecord::Error, Faraday::TimeoutError, Faraday::ConnectionFailed].each do |error_class|
    it "conserve les liens sur #{error_class}" do
      support_module.update!(airtable_content_id: 'recCONTENT')
      allow(Airtables::SupportModuleContent).to receive(:all).and_raise(error_class, 'Indisponible')
      expect(described_class.new.call.errors).not_to be_empty
      expect(support_module.reload.airtable_content_id).to eq('recCONTENT')
    end
  end

  it 'signale une correspondance ambiguë sans choisir un dossier au hasard' do
    allow(Airtables::SupportModuleContent).to receive(:all).and_return([record, record(id: 'recOTHER')])
    expect(described_class.new.call.errors).to include(/Plusieurs dossiers/)
    expect(support_module.reload.airtable_content_id).to be_nil
  end

  it 'ignore les modules archivés' do
    support_module.discard
    described_class.new.call
    expect(support_module.reload.airtable_content_id).to be_nil
  end
end
