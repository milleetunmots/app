require 'rails_helper'

RSpec.describe SupportModuleDecorator do
  describe '#name_without_emoji' do
    # noms réels de la base : l'emoji est saisi dans le nom du module
    {
      "Garder l'intérêt de mon enfant avec les livres 📚" => "Garder l'intérêt de mon enfant avec les livres",
      'Parler avec mon bébé 👶' => 'Parler avec mon bébé',
      'Des idées pour jouer avec mon bébé 🧩' => 'Des idées pour jouer avec mon bébé',
      'Mieux gérer les écrans avec mon enfant 🖥' => 'Mieux gérer les écrans avec mon enfant',
      'Découvrir le monde avec mon enfant pendant les sorties 🌳' => 'Découvrir le monde avec mon enfant pendant les sorties',
      'Parler plusieurs langues à la maison 🏠' => 'Parler plusieurs langues à la maison',
      'Chanter avec mon enfant ♪♪' => 'Chanter avec mon enfant'
    }.each do |name, expected|
      it "retire l'emoji de #{name.inspect}" do
        support_module = FactoryBot.build(:support_module, name: name)

        expect(support_module.decorate.name_without_emoji).to eq(expected)
      end
    end

    it 'laisse intact un nom sans emoji' do
      support_module = FactoryBot.build(:support_module, name: 'Chanter avec mon enfant')

      expect(support_module.decorate.name_without_emoji).to eq('Chanter avec mon enfant')
    end
  end

  describe '#short_age_ranges' do
    it 'compacte une tranche unique' do
      support_module = FactoryBot.build(:support_module, age_ranges: [SupportModule::TWELVE_TO_SEVENTEEN])

      expect(support_module.decorate.short_age_ranges).to eq('12-17')
    end

    it 'compacte plusieurs tranches' do
      support_module = FactoryBot.build(:support_module,
                                        age_ranges: [SupportModule::TWELVE_TO_SEVENTEEN,
                                                     SupportModule::EIGHTEEN_TO_TWENTY_THREE])

      expect(support_module.decorate.short_age_ranges).to eq('12-17 / 18-23')
    end

    it "n'abîme pas le libellé « 23 mois et plus »" do
      support_module = FactoryBot.build(:support_module,
                                        theme: 'language_module_zero',
                                        age_ranges: [SupportModule::TWENTY_THREE_AND_MORE])

      expect(support_module.decorate.short_age_ranges).to eq('23 mois et plus')
    end

    it 'retourne nil sans tranche' do
      support_module = FactoryBot.build(:support_module, age_ranges: [])

      expect(support_module.decorate.short_age_ranges).to be_nil
    end
  end

  # L'URL vient du contenu apparié sur Airtable, pas de l'airtable_id du module :
  # on stubbe la classe Airtables::*, jamais le HTTP
  describe '#airtable_folder_url' do
    let(:support_module) { FactoryBot.build(:support_module) }

    it "pointe vers l'enregistrement Airtable du contenu apparié" do
      allow(Airtables::SupportModuleContent).to receive(:record_url_for)
        .with(support_module).and_return('https://airtable.com/appTEST/tblTEST/recABC123')

      expect(support_module.decorate.airtable_folder_url).to end_with('/recABC123')
    end

    it "retourne nil quand aucun contenu n'est apparié" do
      allow(Airtables::SupportModuleContent).to receive(:record_url_for).and_return(nil)

      expect(support_module.decorate.airtable_folder_url).to be_nil
    end
  end
end
