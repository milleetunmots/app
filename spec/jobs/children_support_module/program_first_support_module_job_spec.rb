require 'rails_helper'

RSpec.describe ChildrenSupportModule::ProgramFirstSupportModuleJob, type: :job do

  subject { described_class }

  let(:group) { FactoryBot.create(:group) }
  let(:program_module_date) { group.started_at }

  describe '#perform_later' do
    it 'enqueues the job' do
      ActiveJob::Base.queue_adapter = :test
      expect {
        subject.perform_later(group.id, program_module_date)
      }.to have_enqueued_job(described_class).on_queue('default').exactly(:once)
    end
  end

  describe '#perform_now' do
    it 'enqueue the job ChildrenSupportModule::ProgramSupportModuleSmsJob' do
      ActiveJob::Base.queue_adapter = :test
      expect { subject.perform_now(group.id, program_module_date) }.to(
        have_enqueued_job(ChildrenSupportModule::ProgramSupportModuleSmsJob)
          .on_queue('default')
          .exactly(:once)
          .with(group.id, program_module_date)
      )
    end

    context 'with new born to 44 months children' do
      let!(:reading_4_11) { FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: "reading", age_ranges: %w[four_to_eleven], name: "Intéresser mon enfant aux livres 📚") }
      let!(:reading_12_17) { FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: "reading", age_ranges: %w[twelve_to_seventeen], name: "Intéresser mon enfant aux livres 📚") }
      let!(:reading_18_23) { FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: "reading", age_ranges: %w[eighteen_to_twenty_three], name: "Intéresser mon enfant aux livres 📚") }
      let!(:reading_24_29) { FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: "reading", age_ranges: %w[twenty_four_to_twenty_nine], name: "Intéresser mon enfant aux livres 📚") }
      let!(:reading_30_35) { FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: "reading", age_ranges: %w[thirty_to_thirty_five], name: "Intéresser mon enfant aux livres 📚") }
      let!(:reading_36_40) { FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: "reading", age_ranges: %w[thirty_six_to_forty], name: "Intéresser mon enfant aux livres 📚") }
      let!(:reading_41_44) { FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: "reading", age_ranges: %w[forty_one_to_forty_four], name: "Intéresser mon enfant aux livres 📚") }

      before do
        (4..43).each do |month|
          child = FactoryBot.create(:child, group: group, group_status: 'active')
          # To avoid the validation of the birth_date
          child.birthdate = month.months.ago
          child.save(validate: false)
        end
      end

      it 'gives a reading support module to each children' do
        expect { subject.perform_now(group.id, program_module_date) }.to change(ChildrenSupportModule, :count).by(40)
        group.children.each do |child|
          expect(child.children_support_modules.count).to eq(1)

          expected_support_module = case child.months
          when 4..11
            reading_4_11
          when 12..17
            reading_12_17
          when 18..23
            reading_18_23
          when 24..29
            reading_24_29
          when 30..35
            reading_30_35
          when 36..40
            reading_36_40
          when 41..44
            reading_41_44
          end

          expect(child.children_support_modules.first.support_module).to eq(expected_support_module)
        end
      end
    end
  end
end
