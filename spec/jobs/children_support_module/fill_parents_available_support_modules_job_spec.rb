require 'rails_helper'

RSpec.describe ChildrenSupportModule::FillParentsAvailableSupportModulesJob, type: :job do

  subject { described_class }

  let(:group) { FactoryBot.create(:group) }

  describe '#perform_later' do
    it 'enqueues the job' do
      ActiveJob::Base.queue_adapter = :test
      expect {
        subject.perform_later(group.id, 3)
      }.to have_enqueued_job(described_class).on_queue('default').exactly(:once)
    end
  end

  describe '#perform_now' do
    before do
      FactoryBot.create(:support_module, level: 2, for_bilingual: false, theme: "reading", age_ranges: %w[twenty_four_to_twenty_nine thirty_to_thirty_five thirty_six_to_forty forty_one_to_forty_four], name: "Garder l'intérêt de mon enfant avec les livres 📚")
      FactoryBot.create(:support_module, level: 2, for_bilingual: false, theme: "reading", age_ranges: %w[twelve_to_seventeen eighteen_to_twenty_three], name: "Garder l'intérêt de mon enfant avec les livres 📚")
      FactoryBot.create(:support_module, level: 2, for_bilingual: false, theme: "reading", age_ranges: %w[five_to_eleven], name: "Garder l'intérêt de mon enfant avec les livres 📚")
      FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: "reading", age_ranges: %w[twenty_four_to_twenty_nine thirty_to_thirty_five thirty_six_to_forty forty_one_to_forty_four], name: "Intéresser mon enfant aux livres 📚")
      FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: "reading", age_ranges: %w[eighteen_to_twenty_three], name: "Intéresser mon enfant aux livres 📚")
      FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: "reading", age_ranges: %w[twelve_to_seventeen], name: "Intéresser mon enfant aux livres 📚")
      FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: "reading", age_ranges: %w[less_than_five five_to_eleven], name: "Intéresser mon enfant aux livres 📚")

      FactoryBot.create(:support_module, level: 1, for_bilingual: true, theme: "bilingualism", age_ranges: %w[twenty_four_to_twenty_nine thirty_to_thirty_five thirty_six_to_forty forty_one_to_forty_four], name: "Parler plusieurs langues à la maison 🏠")
      FactoryBot.create(:support_module, level: 1, for_bilingual: true, theme: "bilingualism", age_ranges: %w[twelve_to_seventeen eighteen_to_twenty_three], name: "Parler plusieurs langues à la maison 🏠")
      FactoryBot.create(:support_module, level: 1, for_bilingual: true, theme: "bilingualism", age_ranges: %w[five_to_eleven], name: "Parler plusieurs langues à la maison 🏠")

      FactoryBot.create(:support_module, level: 3, for_bilingual: false, theme: "language", age_ranges: %w[twenty_four_to_twenty_nine thirty_to_thirty_five thirty_six_to_forty forty_one_to_forty_four], name: "Parler encore plus avec mon enfant")
      FactoryBot.create(:support_module, level: 3, for_bilingual: false, theme: "language", age_ranges: %w[twelve_to_seventeen eighteen_to_twenty_three], name: "Parler encore plus avec mon bébé")
      FactoryBot.create(:support_module, level: 2, for_bilingual: false, theme: "language", age_ranges: %w[five_to_eleven twelve_to_seventeen], name: "Parler plus avec mon bébé")
      FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: "language", age_ranges: %w[five_to_eleven], name: "Parler avec mon bébé 👶")
      FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: "language", age_ranges: %w[less_than_five], name: "Conversation spécial - de 4 mois")

      FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: "anger", age_ranges: %w[eighteen_to_twenty_three twenty_four_to_twenty_nine thirty_to_thirty_five thirty_six_to_forty forty_one_to_forty_four], name: "Parler pour mieux gérer les colères")

      FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: "ride", age_ranges: %w[twelve_to_seventeen], name: "Découvrir le monde avec mon enfant pendant les sorties 🌳")

      FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: "games", age_ranges: %w[five_to_eleven], name: "Des idées pour jouer avec mon bébé 🧩")

      FactoryBot.create(:support_module, level: 2, for_bilingual: false, theme: "screen", age_ranges: %w[eighteen_to_twenty_three twenty_four_to_twenty_nine thirty_to_thirty_five thirty_six_to_forty forty_one_to_forty_four], name: "Mieux gérer les écrans avec mon enfant 🖥")
      FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: "screen", age_ranges: %w[twelve_to_seventeen eighteen_to_twenty_three], name: "Occuper mon enfant (sans les écrans) 🧩")
      FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: "screen", age_ranges: %w[five_to_eleven], name: "Occuper mon enfant (sans les écrans) 🧩")

      FactoryBot.create(:support_module, level: 2, for_bilingual: false, theme: "songs", age_ranges: %w[eighteen_to_twenty_three twenty_four_to_twenty_nine thirty_to_thirty_five thirty_six_to_forty forty_one_to_forty_four], name: "Chanter souvent avec mon bébé 🎶")
      FactoryBot.create(:support_module, level: 2, for_bilingual: false, theme: "songs", age_ranges: %w[twelve_to_seventeen], name: "Chanter souvent avec mon bébé 🎶")
      FactoryBot.create(:support_module, level: 2, for_bilingual: false, theme: "songs", age_ranges: %w[five_to_eleven], name: "Chanter plus avec mon bébé 🎶")
      FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: "songs", age_ranges: %w[eighteen_to_twenty_three twenty_four_to_twenty_nine thirty_to_thirty_five thirty_six_to_forty forty_one_to_forty_four], name: "Chanter avec mon bébé 🎶")
      FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: "songs", age_ranges: %w[twelve_to_seventeen], name: "Chanter avec mon bébé 🎶")
      FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: "songs", age_ranges: %w[five_to_eleven], name: "Chanter avec mon bébé 🎶")


      (0...35).each do |month|
        child = FactoryBot.create(:child, parent2_id: FactoryBot.create(:parent).id, group: group, group_status: 'active')
        # To avoid the validation of the birth_date
        child.birthdate = month.months.ago
        child.save(validate: false)
      end

      # Add first module to children
      ChildrenSupportModule::ProgramFirstSupportModuleJob.perform_now(group.id, Time.zone.today.next_occurring(:monday))

      group.children.each do |child|
        expect(child.children_support_modules.count).to eq(2)
        expect(child.children_support_modules.map(&:support_module).map(&:theme).uniq).to eq(['reading'])
      end

      # Make children module already programmed
      ChildrenSupportModule.update_all(is_programmed: true)
    end

    context 'when this is the second support module' do
      it 'assign new choices for all children' do
        group.update_column(:support_module_sent_dates, {'3' => Time.zone.now})
        subject.perform_now(group.id, 3)

        group.children.each do |child|
          # parent1 ----
          expect(child.child_support.parent1_available_support_module_list).not_to be_blank
          # check the reading module is not in the list
          expect(
            child.child_support.parent1_available_support_module_list & child.children_support_modules.where(parent_id: child.parent1.id).pluck(:support_module_id)
          ).to be_empty
          # check the parent1_available_support_module_list are coherent with the months range of the child
          child.child_support.parent1_available_support_module_list.reject(&:blank?).each do |support_module_id|
            support_module = SupportModule.find(support_module_id)
            expect(support_module.age_ranges).to include(ChildrenSupportModule.new.send(:child_age_range, child.months))
          end

          # parent2 ----
          # check the reading module is not in the list
          expect(child.child_support.parent2_available_support_module_list).not_to be_blank
          expect(
            child.child_support.parent2_available_support_module_list & child.children_support_modules.where(parent_id: child.parent2.id).pluck(:support_module_id)
          ).to be_empty
          child.child_support.parent2_available_support_module_list.reject(&:blank?).each do |support_module_id|
            support_module = SupportModule.find(support_module_id)
            expect(support_module.age_ranges).to include(ChildrenSupportModule.new.send(:child_age_range, child.months))
          end
        end
      end
    end
  end
end
