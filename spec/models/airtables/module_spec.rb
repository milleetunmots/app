require 'rails_helper'

RSpec.describe Airtables::Module do
  # Airrecord tape sur le réseau dès .find/.all : on construit les
  # enregistrements en mémoire, comme les autres specs Airtable du projet
  def airtable_module(titre:, age:)
    described_class.new({ 'titre' => titre, 'age' => age })
  end

  describe '#title' do
    it 'retire les espaces autour du titre' do
      expect(airtable_module(titre: '  Chanter avec mon enfant  ', age: '12-17 mois').title)
        .to eq('Chanter avec mon enfant')
    end

    it 'retourne une chaîne vide quand le titre est absent' do
      expect(described_class.new({}).title).to eq('')
    end
  end

  describe '#support_module' do
    let!(:support_module) do
      FactoryBot.create(:support_module,
                        name: 'Chanter avec mon enfant',
                        age_ranges: [SupportModule::TWELVE_TO_SEVENTEEN])
    end

    it "apparie sur le titre strippé et la tranche d'âge" do
      record = airtable_module(titre: ' Chanter avec mon enfant ', age: '12-17 mois')

      expect(record.support_module).to eq(support_module)
    end

    it "n'apparie pas un module de même nom sur une autre tranche d'âge" do
      record = airtable_module(titre: 'Chanter avec mon enfant', age: '18-23 mois')

      expect(record.support_module).to be_nil
    end

    it "n'apparie pas un module archivé" do
      support_module.discard
      record = airtable_module(titre: 'Chanter avec mon enfant', age: '12-17 mois')

      expect(record.support_module).to be_nil
    end
  end

  describe '.record_url' do
    it "compose l'URL depuis la base, la table et l'enregistrement" do
      expect(described_class.record_url('recABC123'))
        .to eq("https://airtable.com/#{described_class.base_key}/#{described_class.table_name}/recABC123")
    end

    it 'retourne nil sans identifiant' do
      expect(described_class.record_url(nil)).to be_nil
      expect(described_class.record_url('')).to be_nil
    end
  end
end
