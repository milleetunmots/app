require 'rails_helper'

RSpec.describe Media::RcsModelName do
  describe '#to_s' do
    context 'quand le trio est dans des modules V2' do
      it 'donne le thème, le niveau, les tranches d\'âge, la semaine, le numéro du message et le trio' do
        bundle = FactoryBot.create(:media_text_messages_bundle)
        [SupportModule::TWENTY_FOUR_TO_TWENTY_NINE, SupportModule::THIRTY_TO_THIRTY_FIVE].each do |age_range|
          support_module = FactoryBot.create(:support_module, theme: SupportModule::READING, level: 1, age_ranges: [age_range])
          FactoryBot.create(:support_module_week, support_module: support_module, position: 10)
          FactoryBot.create(:support_module_week, support_module: support_module, position: 20, medium: bundle)
        end

        name = described_class.new(text_messages_bundle: bundle, message_index: 3).to_s

        expect(name).to eq("Lecture N1 24-29/30-35 S2M3 ##{bundle.id}")
      end

      it 'écrit 23+ la dernière tranche du module 0' do
        bundle = FactoryBot.create(:media_text_messages_bundle)
        support_module = FactoryBot.create(:support_module, theme: SupportModule::LANGUAGE_MODULE_ZERO, level: 1, age_ranges: [SupportModule::TWENTY_THREE_AND_MORE])
        FactoryBot.create(:support_module_week, support_module: support_module, position: 1, medium: bundle)

        name = described_class.new(text_messages_bundle: bundle, message_index: 3).to_s

        expect(name).to eq("Langage (Module 0) N1 23+ S1M3 ##{bundle.id}")
      end

      it 'numérote 4 le message du trio additionnel de la semaine' do
        bundle = FactoryBot.create(:media_text_messages_bundle)
        support_module = FactoryBot.create(:support_module, theme: SupportModule::SONGS, level: 2, age_ranges: [SupportModule::FOUR_TO_ELEVEN])
        FactoryBot.create(:support_module_week, support_module: support_module, position: 1, additional_medium: bundle)

        name = described_class.new(text_messages_bundle: bundle, message_index: 1).to_s

        expect(name).to eq("Chansons N2 4-11 S1M4 ##{bundle.id}")
      end

      it "ignore un module qui n'est pas V2" do
        bundle = FactoryBot.create(:media_text_messages_bundle, name: 'Livre', tag_list: ['0-12'])
        legacy_module = FactoryBot.create(:support_module, name: 'V1 / 0-12 / S1-S3')
        legacy_module.update_columns(theme: nil)
        FactoryBot.create(:support_module_week, support_module: legacy_module, medium: bundle)

        name = described_class.new(text_messages_bundle: bundle, message_index: 1).to_s

        expect(name).to eq("[0-12] Livre M1 ##{bundle.id}")
      end
    end

    context "quand le trio est celui d'un message automatique" do
      it 'donne sa clé' do
        bundle = FactoryBot.create(:media_text_messages_bundle, name: 'Fin du programme', key: 'fin_programme', tag_list: ['message automatique'])

        name = described_class.new(text_messages_bundle: bundle, message_index: 1).to_s

        expect(name).to eq("Auto fin_programme ##{bundle.id}")
      end
    end

    context "quand le trio est envoyé après l'appel 3" do
      around do |example|
        previous = ENV.fetch('CALL3_TEXT_MESSAGES_BUNDLES', nil)
        ENV['CALL3_TEXT_MESSAGES_BUNDLES'] = 'ParcoursPostAppel3_S26, ParcoursPostAppel3_S27'
        example.run
      ensure
        ENV['CALL3_TEXT_MESSAGES_BUNDLES'] = previous
      end

      it 'donne la semaine de son nom et le numéro du message' do
        bundle = FactoryBot.create(:media_text_messages_bundle, name: 'ParcoursPostAppel3_S27')

        name = described_class.new(text_messages_bundle: bundle, message_index: 2).to_s

        expect(name).to eq("Appel 3 S27M2 ##{bundle.id}")
      end
    end

    context 'quand le trio ne relève d\'aucun de ces cas' do
      it 'donne ses tags, son nom et le numéro du message' do
        bundle = FactoryBot.create(:media_text_messages_bundle, name: 'Rattrapage S28', tag_list: %w[12-24 recap])

        name = described_class.new(text_messages_bundle: bundle, message_index: 2).to_s

        expect(name).to eq("[12-24] [recap] Rattrapage S28 M2 ##{bundle.id}")
      end

      it 'retire les emoji, que Spot-Hit affiche « ? »' do
        bundle = FactoryBot.create(:media_text_messages_bundle, name: 'Chanter avec mon bébé 🎶')

        name = described_class.new(text_messages_bundle: bundle, message_index: 1).to_s

        expect(name).to eq("Chanter avec mon bébé M1 ##{bundle.id}")
      end
    end
  end
end
