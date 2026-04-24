namespace :child_supports do
  desc "Remove '*' characters left by old Typeform webhook payloads in child_support attributes"
  task strip_asterisks: :environment do
    ActiveRecord::Base.transaction do
      pattern = '%*%'

      ChildSupport.where(
        "most_present_parent LIKE :pattern OR important_information LIKE :pattern OR array_to_string(enrollment_reasons, '||') LIKE :pattern",
        pattern: pattern
      ).find_each do |child_support|
        changed = false

        if child_support.most_present_parent&.include?('*')
          child_support.most_present_parent = child_support.most_present_parent.delete('*').strip
          changed = true
        end

        if child_support.important_information&.include?('*')
          child_support.important_information = child_support.important_information.delete('*')
          changed = true
        end

        if child_support.enrollment_reasons.is_a?(Array) && child_support.enrollment_reasons.any? { |reason| reason&.include?('*') }
          child_support.enrollment_reasons = child_support.enrollment_reasons.map { |reason| reason&.delete('*')&.strip }
          changed = true
        end

        next unless changed

        if child_support.save
          puts "ChildSupport ##{child_support.id} cleaned"
        else
          puts "ChildSupport ##{child_support.id} save failed: #{child_support.errors.full_messages.join(', ')}"
        end
      end
    rescue ActiveRecord::RecordInvalid => e
      puts "Erreur : #{e.message}"
      raise ActiveRecord::Rollback
    end
  end
end
