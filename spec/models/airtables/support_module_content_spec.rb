require 'rails_helper'

RSpec.describe Airtables::SupportModuleContent do
  let(:support_module) do
    FactoryBot.build(:support_module, id: 123, name: 'Chanter " avec bébé 🎶',
                     age_ranges: [SupportModule::FOUR_TO_ELEVEN])
  end

  def content(title: support_module.name, age: '04-11 mois', url: nil, id: 'recCONTENT')
    described_class.new({ 'titre' => title, 'Age' => [age], 'SMS envoyés' => url }, id: id)
  end

  describe '.matches_for' do
    it 'apparie le titre exact et la tranche d’âge' do
      expected = content(title: "  #{support_module.name}  ")
      records = [content(age: '12-17 mois'), content(title: 'Autre titre'), expected]
      expect(described_class.matches_for(support_module, records)).to eq([expected])
    end

    it 'départage les niveaux par leur titre si plusieurs dossiers partagent une URL' do
      url = "#{described_class::SUPPORT_MODULE_URL_PREFIX}#{support_module.id}"
      expected = content(url: url)
      records = [content(title: 'Aller plus loin', url: url), expected]
      expect(described_class.matches_for(support_module, records)).to eq([expected])
    end

    it 'utilise l’URL du module si le titre diffère' do
      expected = content(title: 'Autre titre', url: "#{described_class::SUPPORT_MODULE_URL_PREFIX}#{support_module.id}")
      expect(described_class.matches_for(support_module, [expected])).to eq([expected])
    end

    it 'renvoie tous les candidats ambigus pour éviter de choisir arbitrairement' do
      records = [content(id: 'recONE'), content(id: 'recTWO')]
      expect(described_class.matches_for(support_module, records)).to eq(records)
    end

    it 'ne mélange pas les tranches d’âge pour un même titre' do
      expect(described_class.matches_for(support_module, [content(age: '12-17 mois')])).to be_empty
    end

    it 'ignore les modules sans tranche d’âge connue' do
      support_module.age_ranges = []
      expect(described_class.matches_for(support_module, [content])).to be_empty
    end
  end

  describe '.record_url_for' do
    before do
      allow(described_class).to receive(:base_key).and_return('appTEST')
      allow(described_class).to receive(:table_name).and_return('tblTEST')
      allow(described_class).to receive(:all).and_raise('Accès réseau interdit')
    end

    it 'construit le lien depuis l’identifiant stocké, sans appel Airtable' do
      support_module.airtable_content_id = 'recCONTENT'
      expect(described_class.record_url_for(support_module)).to eq(
        'https://airtable.com/appTEST/shrrFRdYIrDKqvy1u/tblTEST/viwvzXW4OIZ0flR7h/recCONTENT'
      )
      expect(described_class).not_to have_received(:all)
    end

    it 'ne confond pas l’identifiant destiné aux livres et celui du contenu' do
      support_module.airtable_id = 'recBOOK'
      expect(described_class.record_url_for(support_module)).to be_nil
    end

    it 'retourne nil sans module' do
      expect(described_class.record_url_for(nil)).to be_nil
    end

    it 'ne construit pas de lien incomplet si la configuration manque' do
      support_module.airtable_content_id = 'recCONTENT'
      allow(described_class).to receive(:base_key).and_return(nil)
      expect(described_class.record_url_for(support_module)).to be_nil
    end
  end
end
