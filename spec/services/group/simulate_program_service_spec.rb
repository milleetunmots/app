require 'rails_helper'

RSpec.describe Group::ProgramService do
  include ActiveJob::TestHelper

  let!(:group) { FactoryBot.create(:group) }
  let!(:children) { [] }
  let!(:csv_data) { [] }

  before do
    allow_any_instance_of(ChildrenSupportModule::CheckCreditsService).to receive(:call).and_return(ChildrenSupportModule::CheckCreditsService.new([]))

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

    FactoryBot.create(:support_module, level: 2, for_bilingual: false, theme: "language", age_ranges: %w[twenty_four_to_twenty_nine thirty_to_thirty_five thirty_six_to_forty forty_one_to_forty_four], name: "Parler encore plus avec mon enfant")
    # FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: "language", age_ranges: %w[], name: "Parler encore plus avec mon bébé")
    FactoryBot.create(:support_module, level: 2, for_bilingual: false, theme: "language", age_ranges: %w[twelve_to_seventeen eighteen_to_twenty_three], name: "Parler encore plus avec mon bébé")
    FactoryBot.create(:support_module, level: 2, for_bilingual: false, theme: "language", age_ranges: %w[five_to_eleven twelve_to_seventeen], name: "Parler plus avec mon bébé")
    # FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: "language", age_ranges: %w[], name: "Parler plus avec mon bébé")
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

    # (1..1000).each do |index|
    #   # birthdate =
    #   #   case index
    #   #   when 1..200
    #   #     3.months.ago
    #   #   when 201..400
    #   #     9.months.ago
    #   #   when 401..600
    #   #     14.months.ago
    #   #   when 601..800
    #   #     19.months.ago
    #   #   when 801..1000
    #   #     26.months.ago
    #   #   when 1001..1200
    #   #     31.months.ago
    #   #   when 1201..1400
    #   #     39.months.ago
    #   #   when 1401..1600
    #   #     43.months.ago
    #   #   end
    #   birthdate = Faker::Date.between(from: 2.months.ago, to: 43.months.ago)
    #   child = FactoryBot.create(:child, group: group, group_status: 'active')
    #   child.birthdate = birthdate
    #   child.save(validate: false)
    #   child.child_support.update!(is_bilingual: (index / 100).odd?)

    #   children << child
    #   csv_data << { child_id: child.id, birthdate: child.birthdate, child_months: child.months, child_bilingual: child.child_support.is_bilingual }
    # end

    JSON.parse(File.read('spec/fixtures/group_mai_23.json')).each do |child_attributes|
      child = FactoryBot.create(:child, group: group, group_status: 'active')
      child.birthdate = child_attributes[0]
      child.save(validate: false)
      child.child_support.update!(is_bilingual: child_attributes[1])

      children << child
      csv_data << { child_id: child.id, birthdate: child.birthdate, child_months: child.months, child_bilingual: child.child_support.is_bilingual }
    end
  end

  after do
    clear_enqueued_jobs
  end

  it 'simulates choices for 1000 children' do
    perform_enqueued_jobs do
      choose_first_module
      extract_first_module_choices
      checks

      make_children_older(2.weeks)

      set_module_availabilites(2)
      extract_modules_availabilites(2)
      choose_module
      extract_module_choices(2)
      program_modules
      checks

      make_children_older(8.weeks)

      set_module_availabilites(3)
      extract_modules_availabilites(3)
      choose_module
      extract_module_choices(3)
      program_modules
      checks

      make_children_older(8.weeks)

      set_module_availabilites(4)
      extract_modules_availabilites(4)
      choose_module
      extract_module_choices(4)
      program_modules
      checks

      write_csv_file
    end
  end

  def csv_data_child_hash(child)
    csv_data.find {|l| l[:child_id] == child.id }
  end

  def display_support_module(support_module)
    return nil if support_module.nil?

    ages = support_module.age_ranges.map do |value|
      case value
      when 'less_than_five'
        '0-4'
      when 'five_to_eleven'
        '5-11'
      when 'twelve_to_seventeen'
        '12-17'
      when 'eighteen_to_twenty_three'
        '18-23'
      when 'twenty_four_to_twenty_nine'
        '24-29'
      when 'thirty_to_thirty_five'
        '30-35'
      when 'thirty_six_to_forty'
        '36-40'
      when 'forty_one_to_forty_four'
        '41-44'
      else
        value
      end
    end
    "theme #{support_module.theme} | #{ages.join(',')} | #{support_module.for_bilingual ? 'bilingue' : 'non-bilingue'} | level #{support_module.level} | #{support_module.name}"
  end

  def make_children_older(weeks)
    children.each do |child|
      child.birthdate = child.birthdate - weeks
      child.save(validate: false)
    end
  end

  def checks
    # tmp fix
    ChildrenSupportModule.update_all(is_programmed: true)
    # expect(ChildrenSupportModule.all.pluck(:is_programmed).uniq).to eq([true])
    # children.each do |child|
    #   child.reload
    #   expect(child.child_support.parent1_available_support_module_list || []).to be_empty
    #   expect(child.child_support.parent2_available_support_module_list || []).to be_empty
    # end
  end

  def choose_first_module
    ChildrenSupportModule::ProgramFirstSupportModuleJob.perform_now(group.id, Date.today.next_occurring(:monday))
  end

  def extract_first_module_choices
    children.each do |child|
      csv_data_child_hash(child)[:'1_module_choice'] = display_support_module(child.children_support_modules.order(created_at: :desc).first&.support_module)
    end
  end

  def set_module_availabilites(index)
    ChildrenSupportModule::FillParentsAvailableSupportModulesJob.perform_now(group.id, index == 2)
  end

  def extract_modules_availabilites(index)
    children.each do |child|
      child.reload
      csv_data_child_hash(child)[:"#{index}_module_availabilities"] =
        child.child_support.parent1_available_support_module_list&.reject(&:blank?)&.map do |sm_id|
          display_support_module(SupportModule.find(sm_id))
        end&.join("\n")
    end
  end

  def choose_module
    ChildrenSupportModule::CreateChildrenSupportModuleJob.perform_now(group.id)

    # default choices
    # ChildrenSupportModule::SelectDefaultSupportModuleJob.perform_now(group.id)

    # random choices
    ChildrenSupportModule.not_programmed.find_each do |csm|
      csm.update!(support_module_id: csm.available_support_module_list.reject(&:blank?).sample)
    end
  end

  def extract_module_choices(index)
    children.each do |child|
      csv_data_child_hash(child)[:"#{index}_module_choice"] = display_support_module(child.children_support_modules.not_programmed.order(created_at: :desc).first&.support_module)
    end
  end

  def program_modules
    ChildrenSupportModule::ProgramSupportModuleSmsJob.perform_now(group.id, Date.today.next_occurring(:monday))
  end

  def write_csv_file
    CSV.open("tmp/cohorte-simulation.csv", "w") do |csv|
      csv << [
        'id',
        'date de naissance',
        'nombre de mois',
        'bilingue',
        '1er : choix',
        '2ème : modules disponibles',
        '2ème : choix',
        '3ème : modules disponibles',
        '3ème : choix',
        '4ème : modules disponibles',
        '4ème : choix',
      ]

      csv_data.each do |child_data|
        csv << [
          child_data[:child_id],
          child_data[:birthdate],
          child_data[:child_months],
          child_data[:child_bilingual],
          child_data[:'1_module_choice'],
          child_data[:'2_module_availabilities'],
          child_data[:'2_module_choice'],
          child_data[:'3_module_availabilities'],
          child_data[:'3_module_choice'],
          child_data[:'4_module_availabilities'],
          child_data[:'4_module_choice'],
        ]
      end
    end
  end
end
