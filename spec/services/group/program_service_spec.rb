require 'rails_helper'

RSpec.describe Group::ProgramService do
  include ActiveJob::TestHelper

  let!(:group) { FactoryBot.create(:group) }

  let!(:four_months_child) { FactoryBot.create(:child, birthdate: Time.zone.now.months_ago(4)) } # four_to_ten
  let!(:ten_months_child) { FactoryBot.create(:child, birthdate: Time.zone.now.months_ago(11)) } # eleven_to_sixteen
  let!(:fifteen_months_child) { FactoryBot.create(:child, birthdate: Time.zone.now.months_ago(15)) } # eleven_to_sixteen
  let!(:twenty_months_child) { FactoryBot.create(:child, birthdate: Time.zone.now.months_ago(20)) } # seventeen_to_twenty_two

  let!(:twenty_six_months_child) { FactoryBot.create(:child, birthdate: Time.zone.now.months_ago(26)) } # twenty_four_and_more
  let!(:thirty_two_months_child) { FactoryBot.create(:child) } # twenty_four_and_more
  let!(:thirty_seven_months_child) { FactoryBot.create(:child) } # twenty_four_and_more
  let!(:forty_two_months_child) { FactoryBot.create(:child) } # twenty_four_and_more

  let!(:four_to_ten_module_zero) { FactoryBot.create(:support_module, level: 1, for_bilingual: true, theme: "language_module_zero", age_ranges: %w[four_to_ten], name: "Enrichir la conversation 4-9") }
  let!(:eleven_to_sixteen_module_zero) { FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: "language_module_zero", age_ranges: %w[eleven_to_sixteen], name: "Enrichir la conversation 10-15") }
  let!(:seventeen_to_twenty_two_module_zero) { FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: "language_module_zero", age_ranges: %w[seventeen_to_twenty_two], name: "Enrichir la conversation 16-23") }
  let!(:twenty_three_and_more_module_zero) { FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: "language_module_zero", age_ranges: %w[twenty_three_and_more], name: "Enrichir la conversation 24 et plus") }

  let!(:four_to_eleven_module_one) { FactoryBot.create(:support_module, level: 1, theme: "reading", age_ranges: %w[four_to_eleven], name: "Intéresser mon enfant aux livres 📚") }
  let!(:twelve_to_seventeen_module_one) { FactoryBot.create(:support_module, level: 1, theme: "reading", age_ranges: %w[twelve_to_seventeen], name: "Intéresser mon enfant aux livres 📚") }
  let!(:eighteen_to_twenty_three_module_one) { FactoryBot.create(:support_module, level: 1, theme: "reading", age_ranges: %w[eighteen_to_twenty_three], name: "Intéresser mon enfant aux livres 📚") }
  let!(:twenty_four_to_twenty_nine_module_one) { FactoryBot.create(:support_module, level: 1, for_bilingual: true, theme: "reading", age_ranges: %w[twenty_four_to_twenty_nine], name: "Intéresser mon enfant aux livres 📚") }
  let!(:thirty_to_thirty_five_module_one) { FactoryBot.create(:support_module, level: 1, theme: "reading", age_ranges: %w[thirty_to_thirty_five], name: "Intéresser mon enfant aux livres 📚") }
  let!(:thirty_six_to_forty_module_one) { FactoryBot.create(:support_module, level: 1, theme: "reading", age_ranges: %w[thirty_six_to_forty], name: "Intéresser mon enfant aux livres 📚") }
  let!(:forty_one_to_forty_four_module_one) { FactoryBot.create(:support_module, level: 1, for_bilingual: true, theme: "reading", age_ranges: %w[forty_one_to_forty_four], name: "Intéresser mon enfant aux livres 📚") }

  before do
    # disable transaction to avoid case where updates made in the job are reverted or something else
    self.use_transactional_tests = false
    thirty_two_months_child.update_column(:birthdate, Time.zone.now.months_ago(32))
    thirty_seven_months_child.update_column(:birthdate, Time.zone.now.months_ago(37))
    forty_two_months_child.update_column(:birthdate, Time.zone.now.months_ago(42))

    stub_request(:post, 'https://www.spot-hit.fr/api/envoyer/sms').to_return(status: 200, body: '{}')
    allow_any_instance_of(Group::StopSupportService).to receive(:call).and_return(Group::StopSupportService.new(group.id))
  end

  after do
    clear_enqueued_jobs
    self.use_transactional_tests = true
  end

  context 'when module zero is programmed' do
    it 'a zero module support module is selected for each child according to their age' do
      ChildrenSupportModule::ProgramSupportModuleZeroJob.perform_now(group.id, Time.zone.now.next_occurring(:monday))

      expect(four_months_child.reload.children_support_modules.map(&:support_module_id)).to match_array [four_to_ten_module_zero.id]
      expect(ten_months_child.reload.children_support_modules.map(&:support_module_id)).to match_array [eleven_to_sixteen_module_zero.id]
      expect(fifteen_months_child.reload.children_support_modules.map(&:support_module_id)).to match_array [eleven_to_sixteen_module_zero.id]
      expect(twenty_months_child.reload.children_support_modules.map(&:support_module_id)).to match_array [seventeen_to_twenty_two_module_zero.id]
      expect(twenty_six_months_child.reload.children_support_modules.map(&:support_module_id)).to match_array [twenty_three_and_more_module_zero.id]
      expect(thirty_two_months_child.reload.children_support_modules.map(&:support_module_id)).to match_array [twenty_three_and_more_module_zero.id]
      expect(thirty_seven_months_child.reload.children_support_modules.map(&:support_module_id)).to match_array [twenty_three_and_more_module_zero.id]
      expect(forty_two_months_child.reload.children_support_modules.map(&:support_module_id)).to match_array [twenty_three_and_more_module_zero.id]
    end
  end

  context 'when module one is programmed' do
    it 'a module one support module is selected for each child according to their age' do
      ChildrenSupportModule::ProgramFirstSupportModuleJob.perform_now(group.id, Time.zone.now.next_occurring(:monday))

      expect(ten_months_child.reload.children_support_modules.map(&:support_module_id)).to match_array [four_to_eleven_module_one.id]
      expect(fifteen_months_child.reload.children_support_modules.map(&:support_module_id)).to match_array [twelve_to_seventeen_module_one.id]
      expect(twenty_months_child.reload.children_support_modules.map(&:support_module_id)).to match_array [eighteen_to_twenty_three_module_one.id]
      expect(twenty_six_months_child.reload.children_support_modules.map(&:support_module_id)).to match_array [twenty_four_to_twenty_nine_module_one.id]
      expect(thirty_two_months_child.reload.children_support_modules.map(&:support_module_id)).to match_array [thirty_to_thirty_five_module_one.id]
      expect(thirty_seven_months_child.reload.children_support_modules.map(&:support_module_id)).to match_array [thirty_six_to_forty_module_one.id]
      expect(forty_two_months_child.reload.children_support_modules.map(&:support_module_id)).to match_array [forty_one_to_forty_four_module_one.id]
    end
  end
end
