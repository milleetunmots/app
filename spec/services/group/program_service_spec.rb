require 'rails_helper'

RSpec.describe Group::ProgramService do
  include ActiveJob::TestHelper

  let!(:group) { FactoryBot.create(:group) }

  # let!(:four_months_child) { FactoryBot.create(:child, birthdate: Time.zone.now.months_ago(4)) } # four_to_nine
  # let!(:ten_months_child) { FactoryBot.create(:child, birthdate: Time.zone.now.months_ago(10)) } # ten_to_fifteen
  let!(:fifteen_months_child) { FactoryBot.create(:child, birthdate: Time.zone.now.months_ago(15)) } # ten_to_fifteen
  # let!(:twenty_months_child) { FactoryBot.create(:child, birthdate: Time.zone.now.months_ago(20)) } # sixteen_to_twenty_three
  # let!(:twenty_six_months_child) { FactoryBot.create(:child, birthdate: Time.zone.now.months_ago(26)) } # more_than_twenty_four
  # let!(:thirty_two_months_child) { FactoryBot.create(:child) } # more_than_twenty_four
  # let!(:thirty_seven_months_child) { FactoryBot.create(:child) } # more_than_twenty_four
  # let!(:forty_two_months_child) { FactoryBot.create(:child) } # more_than_twenty_four

  let!(:four_to_nine_module_zero) { FactoryBot.create(:support_module, level: 1, for_bilingual: true, theme: "language_module_zero", age_ranges: %w[four_to_nine], name: "Enrichir la conversation 4-9") }
  let!(:ten_to_fifteen_module_zero) { FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: "language_module_zero", age_ranges: %w[ten_to_fifteen], name: "Enrichir la conversation 10-15") }
  let!(:sixteen_to_twenty_three_module_zero) { FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: "language_module_zero", age_ranges: %w[sixteen_to_twenty_three], name: "Enrichir la conversation 16-23") }
  let!(:more_than_twenty_four_module_zero) { FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: "language_module_zero", age_ranges: %w[more_than_twenty_four], name: "Enrichir la conversation 24 et plus") }

  let!(:less_than_five_module_one) { FactoryBot.create(:support_module, level: 1, for_bilingual: true, theme: "reading", age_ranges: %w[less_than_five], name: "Intéresser mon enfant aux livres 📚") }
  let!(:five_to_eleven_module_one) { FactoryBot.create(:support_module, level: 1, theme: "reading", age_ranges: %w[five_to_eleven], name: "Intéresser mon enfant aux livres 📚") }
  let!(:twelve_to_seventeen_module_one) { FactoryBot.create(:support_module, level: 1, theme: "reading", age_ranges: %w[twelve_to_seventeen], name: "Intéresser mon enfant aux livres 📚") }
  let!(:eighteen_to_twenty_three_module_one) { FactoryBot.create(:support_module, level: 1, theme: "reading", age_ranges: %w[eighteen_to_twenty_three], name: "Intéresser mon enfant aux livres 📚") }
  let!(:twenty_four_to_twenty_nine_module_one) { FactoryBot.create(:support_module, level: 1, for_bilingual: true, theme: "reading", age_ranges: %w[twenty_four_to_twenty_nine], name: "Intéresser mon enfant aux livres 📚") }
  let!(:thirty_to_thirty_five_module_one) { FactoryBot.create(:support_module, level: 1, theme: "reading", age_ranges: %w[thirty_to_thirty_five], name: "Intéresser mon enfant aux livres 📚") }
  let!(:thirty_six_to_forty_module_one) { FactoryBot.create(:support_module, level: 1, theme: "reading", age_ranges: %w[thirty_six_to_forty], name: "Intéresser mon enfant aux livres 📚") }
  let!(:forty_one_to_forty_four_module_one) { FactoryBot.create(:support_module, level: 1, for_bilingual: true, theme: "reading", age_ranges: %w[forty_one_to_forty_four], name: "Intéresser mon enfant aux livres 📚") }

  before do
    # thirty_two_months_child.update(birthdate: Time.zone.now.months_ago(32))
    # thirty_seven_months_child.update(birthdate: Time.zone.now.months_ago(37))
    # forty_two_months_child.update(birthdate: Time.zone.now.months_ago(42))

    allow_any_instance_of(ChildrenSupportModule::CheckCreditsService).to receive(:call).and_return(ChildrenSupportModule::CheckCreditsService.new([]))
    stub_request(:post, 'https://www.spot-hit.fr/api/envoyer/sms').to_return(status: 200, body: '{}')
  end

  after do
    clear_enqueued_jobs
  end

  context 'when module zero is programmed' do
    xit 'a zero module support module is selected for each child according to their age' do
      ChildrenSupportModule::ProgramSupportModuleZeroJob.perform_now(group.id, Time.zone.now.next_occurring(:monday))

      # expect(four_months_child.children_support_modules.pluck(:id)).to match_array [four_to_nine_module_zero.id]
      # expect(ten_months_child.children_support_modules.pluck(:id)).to match_array [ten_to_fifteen_module_zero.id]
      expect(fifteen_months_child.children_support_modules.pluck(:id)).to match_array [ten_to_fifteen_module_zero.id]
      # expect(twenty_months_child.children_support_modules.pluck(:id)).to match_array [sixteen_to_twenty_three_module_zero.id]
      # expect(twenty_six_months_child.children_support_modules.pluck(:id)).to match_array [more_than_twenty_four_module_zero.id]
      # expect(thirty_two_months_child.children_support_modules.pluck(:id)).to match_array [more_than_twenty_four_module_zero.id]
      # expect(thirty_seven_months_child.children_support_modules.pluck(:id)).to match_array [more_than_twenty_four_module_zero.id]
      # expect(forty_two_months_child.children_support_modules.pluck(:id)).to match_array [more_than_twenty_four_module_zero.id]
    end
  end
end
