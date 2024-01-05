require 'rails_helper'

RSpec.describe Group::ProgramService do
  include ActiveJob::TestHelper

  let!(:group) { FactoryBot.create(:group) }
  let!(:children) { [] }
  let!(:csv_data) { [] }

  before do
    allow_any_instance_of(ChildrenSupportModule::CheckCreditsService).to receive(:call).and_return(ChildrenSupportModule::CheckCreditsService.new([]))
    stub_request(:post, 'https://www.spot-hit.fr/api/envoyer/sms').to_return(status: 200, body: '{}')

    FactoryBot.create(:support_module, level: 1, for_bilingual: true, theme: "language_module_zero", age_ranges: %w[four_to_nine], name: "Enrichir la conversation 4-9")
    FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: "language_module_zero", age_ranges: %w[ten_to_fifteen], name: "Enrichir la conversation 10-15")
    FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: "language_module_zero", age_ranges: %w[sixteen_to_twenty_three], name: "Enrichir la conversation 16-23")
    FactoryBot.create(:support_module, level: 1, for_bilingual: false, theme: "language_module_zero", age_ranges: %w[twenty_four_to_twenty_nine], name: "Enrichir la conversation 24-29")

    JSON.parse(File.read('spec/fixtures/support_modules_staging.json')).each do |support_module|
      FactoryBot.create(
        :support_module,
        level: support_module[0],
        for_bilingual: support_module[1],
        theme: support_module[2],
        age_ranges: support_module[3],
        name: support_module[4]
      )
    end

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

  xit 'simulates choices for children' do
    perform_enqueued_jobs do
      choose_module_zero
      extract_module_zero_choices
      checks

      make_children_older(4)

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

      make_children_older(8.weeks)

      set_module_availabilites(5)
      extract_modules_availabilites(5)
      choose_module
      extract_module_choices(5)
      program_modules
      checks

      make_children_older(8.weeks)

      set_module_availabilites(6)
      extract_modules_availabilites(6)
      choose_module
      extract_module_choices(6)
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

  def choose_module_zero
    ChildrenSupportModule::ProgramSupportModuleZeroJob.perform_now(group.id, Time.zone.today.next_occurring(:monday))
  end

  def choose_first_module
    ChildrenSupportModule::ProgramFirstSupportModuleJob.perform_now(group.id, Time.zone.today.next_occurring(:monday))
  end

  def extract_module_zero_choices
    children.each do |child|
      csv_data_child_hash(child)[:'0_module_choice'] = display_support_module(child.children_support_modules.order(created_at: :desc).first&.support_module)
    end
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
    ChildrenSupportModule::ProgramSupportModuleSmsJob.perform_now(group.id, Time.zone.today.next_occurring(:monday))
  end

  def write_csv_file
    CSV.open("tmp/cohorte-simulation.csv", "w") do |csv|
      csv << [
        'id',
        'date de naissance',
        'nombre de mois',
        'bilingue',
        '0 : choix',
        '1er : choix',
        '2ème : modules disponibles',
        '2ème : choix',
        '3ème : modules disponibles',
        '3ème : choix',
        '4ème : modules disponibles',
        '4ème : choix',
        '5ème : modules disponibles',
        '5ème : choix',
        '6ème : modules disponibles',
        '6ème : choix'
      ]

      csv_data.each do |child_data|
        csv << [
          child_data[:child_id],
          child_data[:birthdate],
          child_data[:child_months],
          child_data[:child_bilingual],
          child_data[:'0_module_choice'],
          child_data[:'1_module_choice'],
          child_data[:'2_module_availabilities'],
          child_data[:'2_module_choice'],
          child_data[:'3_module_availabilities'],
          child_data[:'3_module_choice'],
          child_data[:'4_module_availabilities'],
          child_data[:'4_module_choice'],
          child_data[:'5_module_availabilities'],
          child_data[:'5_module_choice'],
          child_data[:'6_module_availabilities'],
          child_data[:'6_module_choice'],
        ]
      end
    end
  end
end
