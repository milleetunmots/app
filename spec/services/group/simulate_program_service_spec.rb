require 'rails_helper'

RSpec.describe Group::ProgramService do
  include ActiveJob::TestHelper

  let!(:group) { FactoryBot.create(:group) }
  let!(:children) { [] }
  let!(:csv_data) { [] }

  before do
    allow_any_instance_of(ChildrenSupportModule::CheckCreditsService).to receive(:call).and_return(ChildrenSupportModule::CheckCreditsService.new([]))

    FactoryBot.create(:support_module, level: 2, for_bilingual: false, theme: "reading", age_ranges: %w[twenty_four_to_thirty_one], name: "Garder l'intérêt de mon enfant avec les livres 📚")
    FactoryBot.create(:support_module, level: 2, for_bilingual: false, theme: "reading", age_ranges: %w[eighteen_to_twenty_three], name: "Garder l'intérêt de mon enfant avec les livres 📚")
    FactoryBot.create(:support_module, level: 2, for_bilingual: false, theme: "reading", age_ranges: %w[six_to_eleven], name: "Garder l'intérêt de mon enfant avec les livres 📚")
    FactoryBot.create(:support_module, level: 2, for_bilingual: false, theme: "reading", age_ranges: %w[twelve_to_seventeen], name: "Garder l'intérêt de mon enfant avec les livres 📚")
    FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: "reading", age_ranges: %w[twenty_four_to_thirty_one], name: "Intéresser mon enfant aux livres 📚")
    FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: "reading", age_ranges: %w[eighteen_to_twenty_three], name: "Intéresser mon enfant aux livres 📚")
    FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: "reading", age_ranges: %w[twelve_to_seventeen], name: "Intéresser mon enfant aux livres 📚")
    FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: "reading", age_ranges: %w[six_to_eleven], name: "Intéresser mon enfant aux livres 📚")

    FactoryBot.create(:support_module, level: 1, for_bilingual: true, theme: "language", age_ranges: %w[twenty_four_to_thirty_one], name: "Parler plusieurs langues à la maison 🏠")
    FactoryBot.create(:support_module, level: 1, for_bilingual: true, theme: "language", age_ranges: %w[twelve_to_seventeen eighteen_to_twenty_three], name: "Parler plusieurs langues à la maison 🏠")
    FactoryBot.create(:support_module, level: 1, for_bilingual: true, theme: "language", age_ranges: %w[less_than_six six_to_eleven], name: "Parler plusieurs langues à la maison 🏠")
    FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: "language", age_ranges: %w[twenty_four_to_thirty_one], name: "Parler encore plus avec mon bébé")
    FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: "language", age_ranges: %w[eighteen_to_twenty_three], name: "Parler encore plus avec mon bébé")
    FactoryBot.create(:support_module, level: 2, for_bilingual: false, theme: "language", age_ranges: %w[twelve_to_seventeen], name: "Parler encore plus avec mon bébé")
    FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: "language", age_ranges: %w[twelve_to_seventeen], name: "Parler plus avec mon bébé")
    FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: "language", age_ranges: %w[six_to_eleven], name: "Parler plus avec mon bébé")
    FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: "language", age_ranges: %w[six_to_eleven], name: "Parler avec mon bébé 👶")
    FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: "language", age_ranges: %w[twelve_to_seventeen eighteen_to_twenty_three], name: "Découvrir le monde avec mon enfant pendant les sorties 🌳")
    FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: "language", age_ranges: %w[twelve_to_seventeen eighteen_to_twenty_three], name: "Comprendre et gérer sa colère 😠")

    FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: "games", age_ranges: %w[six_to_eleven], name: "Des idées pour jouer avec mon bébé 🧩")

    FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: "screen", age_ranges: %w[twelve_to_seventeen eighteen_to_twenty_three], name: "Occuper mon enfant (sans les écrans) 🧩")
    FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: "screen", age_ranges: %w[six_to_eleven], name: "Occuper mon enfant (sans les écrans) 🧩")
    FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: "screen", age_ranges: %w[twelve_to_seventeen eighteen_to_twenty_three], name: "Mieux gérer les écrans avec mon enfant 🖥")

    FactoryBot.create(:support_module, level: 2, for_bilingual: false, theme: "songs", age_ranges: %w[eighteen_to_twenty_three twenty_four_to_thirty_one], name: "Chanter souvent avec mon bébé 🎶")
    FactoryBot.create(:support_module, level: 2, for_bilingual: false, theme: "songs", age_ranges: %w[twelve_to_seventeen], name: "Chanter souvent avec mon bébé 🎶")
    FactoryBot.create(:support_module, level: 2, for_bilingual: false, theme: "songs", age_ranges: %w[six_to_eleven], name: "Chanter souvent avec mon bébé 🎶")
    FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: "songs", age_ranges: %w[eighteen_to_twenty_three twenty_four_to_thirty_one], name: "Chanter avec mon bébé 🎶")
    FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: "songs", age_ranges: %w[twelve_to_seventeen], name: "Chanter avec mon bébé 🎶")
    FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: "songs", age_ranges: %w[six_to_eleven], name: "Chanter avec mon bébé 🎶")


    1000.times do
      child = FactoryBot.create(:child, group: group, group_status: 'active')
      child.child_support.update!(is_bilingual: false)

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

      set_module_availabilites(2)
      extract_modules_availabilites(2)
      choose_module
      extract_module_choices(2)
      program_modules
      checks

      set_module_availabilites(3)
      extract_modules_availabilites(3)
      choose_module
      extract_module_choices(3)
      program_modules
      checks

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
      when 'less_than_six'
        '0-5'
      when 'six_to_eleven'
        '6-11'
      when 'twelve_to_seventeen'
        '12-17'
      when 'eighteen_to_twenty_three'
        '18-23'
      end
    end
    "theme #{support_module.theme} | #{ages.join(',')} | #{support_module.for_bilingual ? 'bilingue' : 'non-bilingue'} | level #{support_module.level} | #{support_module.name}"
  end

  def checks
    # tmp fix
    ChildrenSupportModule.update_all(is_programmed: true)
    # expect(ChildrenSupportModule.all.pluck(:is_programmed).uniq).to eq([true])
    children.each do |child|
      child.reload
      expect(child.child_support.parent1_available_support_module_list || []).to be_empty
      expect(child.child_support.parent2_available_support_module_list || []).to be_empty
    end
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
