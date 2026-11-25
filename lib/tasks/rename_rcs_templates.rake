# One-shot, à lancer en production après rcs:create_templates : la base de production porte le contenu à jour des modèles.
namespace :rcs do
  desc 'Rename existing RCS templates of kept text bundles after their module, week and message (Spot-Hit replaces the whole template)'
  task rename_templates: :environment do
    if ENV['SPOT_HIT_SAFEGUARD'].present?
      puts 'Aborted: SPOT_HIT_SAFEGUARD active. Refusing to sync RCS templates to SpotHit.'
      exit 0
    end

    renamed_count = 0
    errors = []

    Media::TextMessagesBundle.kept.find_each do |bundle|
      (1..3).each do |message_index|
        next if bundle.public_send("rcs_media#{message_index}_id").blank? || bundle.public_send("body#{message_index}").blank?

        service = SpotHit::UpdateRcsModelService.new(text_messages_bundle: bundle, message_index: message_index).call
        label = "Bundle ##{bundle.id} message #{message_index} (template #{bundle.public_send("rcs_media#{message_index}_id")})"
        if service.errors.any?
          errors << "#{label}: ERROR - #{service.errors.join(', ')}"
          puts errors.last
        else
          renamed_count += 1
          puts "#{label}: renamed"
        end
        sleep 0.5
      end
    end

    puts "\nTemplates renamed: #{renamed_count}"
    puts "Errors: #{errors.size}"
    errors.each { |error| puts "  #{error}" }
  end
end
