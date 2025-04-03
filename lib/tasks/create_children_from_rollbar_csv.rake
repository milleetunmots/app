require 'csv'

namespace :children do
  desc 'Create children from Rollbar CSV'
  task create_from_rollbar_csv: :environment do
    
    first_rollbar_csv_path = ENV['FIRST_ROLLBAR_CSV_PATH']
    second_rollbar_csv_path = ENV['SECOND_ROLLBAR_CSV_PATH']
    handle_file(first_rollbar_csv_path)
    p '#############################'
    p 'second'
    p '#############################'
    handle_file(second_rollbar_csv_path)
    end
  end

  def handle_file(file_path)
    children = []
    CSV.foreach(file_path, headers: true) do |row|
      next if "#{row['request.POST.child.first_name'].strip.downcase} #{row['request.POST.child.last_name'].strip.downcase}".in? children

      attributes = {
        gender: row['request.POST.child.gender'],
        first_name: row['request.POST.child.first_name'],
        last_name: row['request.POST.child.last_name'],
        'birthdate(3i)' => row['request.POST.child.birthdate(3i)'],
        'birthdate(2i)' => row['request.POST.child.birthdate(2i)'],
        'birthdate(1i)' => row['request.POST.child.birthdate(1i)'],
        tag_list: row['request.POST.child.tag_list'].split(' '),
        child_support_attributes: {},
        src_url: row['request.url']
      }
      siblings_attributes = []
      parent1_attributes = {
        letterbox_name: row['request.POST.child.parent1_attributes.letterbox_name'],
        address: row['request.POST.child.parent1_attributes.address'],
        postal_code: row['request.POST.child.parent1_attributes.postal_code'],
        city_name: row['request.POST.child.parent1_attributes.city_name'],
        first_name: row['request.POST.child.parent1_attributes.first_name'],
        last_name: row['request.POST.child.parent1_attributes.last_name'],
        phone_number: "0#{row['request.POST.child.parent1_attributes.phone_number']}",
        gender: row['request.POST.child.parent1_attributes.gender'],
        degree_country_at_registration: row['request.POST.child.parent1_attributes.degree_country_at_registration'],
        degree_level_at_registration: row['request.POST.child.parent1_attributes.degree_level_at_registration'],
        address_supplement: row['request.POST.child.parent1_attributes.address_supplement']
      }
      parent2_attributes = {
        first_name: row['request.POST.child.parent2_attributes.first_name'] || '',
        last_name: row['request.POST.child.parent2_attributes.last_name'] || '',
        phone_number: row['request.POST.child.parent2_attributes.last_name'] == '' ? '' : "0#{row['request.POST.child.parent2_attributes.last_name']}",
        gender: row['request.POST.child.parent2_attributes.first_name'] == '' ? '' : row['request.POST.child.parent2_attributes.gender']
      }
      registration_origin = row['request.session.registration_origin'].to_i
      children_source_attributes = {
        source_id: row['request.POST.child.children_source_attributes.source_id'],
        details: row['request.POST.child.children_source_attributes.details']
      }
      child_min_birthdate = Child.min_birthdate

      service = Child::CreateService.new(
        attributes,
        siblings_attributes,
        parent1_attributes,
        parent2_attributes,
        registration_origin,
        children_source_attributes,
        child_min_birthdate
      ).call

      child = service.child

      if child.errors.any?
        p child.errors
        Rollbar.error( 'Error creating child from Rollbar CSV', errors: child.errors)
      end

      p child.id
      children << "#{child.first_name.strip.downcase} #{child.last_name.strip.downcase}"
  end
  p children
end

