require 'rails_helper'

RSpec.describe SupportModule::SyncAirtableIdsService do
  # convention du projet : on stubbe les classes Airtables::*, jamais le HTTP
  def airtable_record(id, support_module)
    instance_double(Airtables::Module,
                    id: id,
                    title: support_module.name,
                    ages: support_module.age_ranges.first,
                    support_module: SupportModule.find_by(id: support_module.id))
  end

  def unmatched_airtable_record(id, title: 'Module inconnu', ages: SupportModule::TWELVE_TO_SEVENTEEN)
    instance_double(Airtables::Module, id: id, title: title, ages: ages, support_module: nil)
  end

  def stub_airtable(records)
    allow(Airtables::Module).to receive(:all).and_return(records)
  end

  let!(:support_module) do
    FactoryBot.create(:support_module,
                      name: 'Chanter avec mon enfant',
                      age_ranges: [SupportModule::TWELVE_TO_SEVENTEEN])
  end

  it "renseigne l'identifiant Airtable du module apparié" do
    stub_airtable([airtable_record('recAAA', support_module)])

    service = described_class.new.call

    expect(service.errors).to be_empty
    expect(support_module.reload.airtable_id).to eq('recAAA')
  end

  it "n'écrit pas quand l'identifiant est déjà à jour" do
    support_module.update!(airtable_id: 'recAAA')
    stub_airtable([airtable_record('recAAA', support_module)])

    expect { described_class.new.call }.not_to change { support_module.reload.updated_at }
  end

  it 'signale les modules Airtable non appariés' do
    stub_airtable([unmatched_airtable_record('recBBB', title: 'Module inconnu')])

    service = described_class.new.call

    expect(service.errors).to contain_exactly("Module inconnu #{SupportModule::TWELVE_TO_SEVENTEEN} introuvable")
  end

  it "libère l'identifiant détenu par un module archivé avant de le réaffecter" do
    archived = FactoryBot.create(:support_module, airtable_id: 'recAAA')
    archived.discard
    stub_airtable([airtable_record('recAAA', support_module)])

    service = described_class.new.call

    expect(service.errors).to be_empty
    expect(support_module.reload.airtable_id).to eq('recAAA')
    expect(SupportModule.unscoped.find(archived.id).airtable_id).to be_nil
  end

  it "efface l'identifiant d'un module retiré d'Airtable" do
    removed = FactoryBot.create(:support_module, airtable_id: 'recOLD')
    stub_airtable([airtable_record('recAAA', support_module)])

    described_class.new.call

    expect(removed.reload.airtable_id).to be_nil
  end

  it "n'efface rien quand aucun module n'a été apparié" do
    support_module.update!(airtable_id: 'recAAA')
    stub_airtable([unmatched_airtable_record('recBBB')])

    described_class.new.call

    expect(support_module.reload.airtable_id).to eq('recAAA')
  end

  it "préserve les identifiants existants si l'appariement est seulement partiel" do
    other_module = FactoryBot.create(:support_module, airtable_id: 'recBBB')
    stub_airtable([airtable_record('recAAA', support_module), unmatched_airtable_record('recBBB')])

    service = described_class.new.call

    expect(service.errors).not_to be_empty
    expect(other_module.reload.airtable_id).to eq('recBBB')
  end

  it 'ignore la synchronisation quand Airtable ne renvoie aucun module' do
    support_module.update!(airtable_id: 'recAAA')
    stub_airtable([])

    service = described_class.new.call

    expect(service.errors).to contain_exactly('Aucun module récupéré depuis Airtable, synchronisation ignorée par sécurité.')
    expect(support_module.reload.airtable_id).to eq('recAAA')
  end

  it 'remonte les erreurs Airtable' do
    allow(Airtables::Module).to receive(:all).and_raise(Airrecord::Error, 'HTTP 404: not found')

    service = described_class.new.call

    expect(service.errors).to contain_exactly('Erreur Airtable lors de la récupération des modules : HTTP 404: not found')
  end
end
