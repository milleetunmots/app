require 'rails_helper'

RSpec.describe Airtables::SupportModuleContent do
  # Airrecord tape sur le réseau dès .all : on construit les enregistrements en
  # mémoire et on stubbe la requête, comme les autres specs Airtable du projet
  def support_module_content(titre:, age:, id: 'recABC123', support_module_id: nil, niveau: nil)
    described_class.new(
      {
        'titre' => titre,
        'Age' => [age],
        'Niveau' => niveau,
        'SMS envoyés' => support_module_id && "#{described_class::SUPPORT_MODULE_URL_PREFIX}#{support_module_id}"
      }.compact,
      id: id
    )
  end

  let(:support_module) do
    FactoryBot.create(:support_module,
                      name: 'Chanter avec mon bébé 🎶',
                      age_ranges: [SupportModule::FOUR_TO_ELEVEN])
  end

  describe '.for_support_module' do
    before { allow(described_class).to receive(:all).and_return([]) }

    it 'retourne nil sans module' do
      expect(described_class.for_support_module(nil)).to be_nil
      expect(described_class).not_to have_received(:all)
    end

    it "n'interroge pas Airtable quand le module n'a pas de tranche d'âge" do
      # Les modules d'onboarding et de rattrapage, antérieurs à la validation, en sont dépourvus
      without_age_range = FactoryBot.build(:support_module, age_ranges: [])

      expect(described_class.for_support_module(without_age_range)).to be_nil
      expect(described_class).not_to have_received(:all)
    end

    it "n'interroge pas Airtable pour une tranche d'âge sans équivalent Airtable" do
      support_module.update!(age_ranges: [SupportModule::THIRTY_SIX_TO_FORTY])

      expect(described_class.for_support_module(support_module)).to be_nil
      expect(described_class).not_to have_received(:all)
    end

    it "filtre sur la tranche d'âge Airtable, le titre et l'URL du module" do
      described_class.for_support_module(support_module)

      expect(described_class).to have_received(:all).with(
        filter: 'AND( ARRAYJOIN({Age}) = "04-11 mois", OR( TRIM({titre}) = "Chanter avec mon bébé 🎶", ' \
                "{SMS envoyés} = \"#{described_class::SUPPORT_MODULE_URL_PREFIX}#{support_module.id}\" ) )"
      )
    end

    it 'échappe les guillemets du titre dans la formule' do
      support_module.update!(name: 'Chanter " avec mon bébé')

      described_class.for_support_module(support_module)

      expect(described_class).to have_received(:all)
        .with(filter: a_string_including('TRIM({titre}) = "Chanter \" avec mon bébé"'))
    end

    it 'retourne nil quand aucun contenu ne correspond' do
      expect(described_class.for_support_module(support_module)).to be_nil
    end

    # Deux contenus portent l'URL du module 127 : celui de niveau 1 et celui de
    # niveau 2, dont le titre diffère. Le titre départage.
    it 'privilégie le contenu dont le titre correspond au nom du module' do
      other_level = support_module_content(titre: 'Chanter souvent avec mon bébé 🎶', age: '04-11 mois',
                                           support_module_id: support_module.id, niveau: 'Aller plus loin')
      expected = support_module_content(titre: 'Chanter avec mon bébé 🎶', age: '04-11 mois',
                                        support_module_id: support_module.id, niveau: 'Pour débuter')
      allow(described_class).to receive(:all).and_return([other_level, expected])

      expect(described_class.for_support_module(support_module)).to eq(expected)
    end

    # Le nom en base porte la tranche d'âge en suffixe, absente du titre Airtable
    it "se rabat sur l'URL quand aucun titre ne correspond" do
      module_zero = FactoryBot.create(:support_module,
                                      name: 'Module 0 conversation 4-10',
                                      theme: SupportModule::LANGUAGE_MODULE_ZERO,
                                      age_ranges: [SupportModule::FOUR_TO_TEN])
      expected = support_module_content(titre: 'Module 0 conversation', age: '4-10 mois',
                                        support_module_id: module_zero.id)
      allow(described_class).to receive(:all).and_return([expected])

      expect(described_class.for_support_module(module_zero)).to eq(expected)
    end
  end

  describe '.record_url_for' do
    # rails_helper neutralise cette méthode pour le rendu des vues : ici on teste
    # la vraie implémentation
    before { allow(described_class).to receive(:record_url_for).and_call_original }

    it "compose l'URL depuis la base, la table et l'enregistrement apparié" do
      record = support_module_content(titre: 'Chanter avec mon bébé 🎶', age: '04-11 mois', id: 'recABC123')
      allow(described_class).to receive(:all).and_return([record])

      expect(described_class.record_url_for(support_module)).to eq(
        "https://airtable.com/#{described_class.base_key}/shrrFRdYIrDKqvy1u/" \
        "#{described_class.table_name}/viwvzXW4OIZ0flR7h/recABC123"
      )
    end

    it 'retourne nil quand aucun contenu ne correspond' do
      allow(described_class).to receive(:all).and_return([])

      expect(described_class.record_url_for(support_module)).to be_nil
    end

    it 'retourne nil sans module' do
      expect(described_class.record_url_for(nil)).to be_nil
    end
  end

  describe '#title' do
    it 'retire les espaces autour du titre' do
      expect(support_module_content(titre: '  Chanter avec mon bébé 🎶  ', age: '04-11 mois').title)
        .to eq('Chanter avec mon bébé 🎶')
    end

    it 'retourne une chaîne vide quand le titre est absent' do
      expect(described_class.new({}).title).to eq('')
    end
  end
end
