# One-shot : modèles texte créés depuis une copie locale de la base, à rattacher aux trios de staging et de production.
require 'csv'

namespace :rcs do
  default_path = Rails.root.join('lib/tasks/data/rcs_template_ids.csv').to_s
  headers = %w[bundle_id key bundle_name message_index rcs_media_id]

  desc 'Export the text template id of every kept text bundle message to a CSV file'
  task :export_template_ids, [:path] => :environment do |_task, args|
    path = args[:path] || default_path
    count = 0
    CSV.open(path, 'w') do |csv|
      csv << headers
      Media::TextMessagesBundle.kept.order(:id).find_each do |bundle|
        (1..3).select { |index| bundle.public_send("rcs_text_template#{index}") && bundle.public_send("rcs_media#{index}_id").present? }.each do |index|
          csv << [bundle.id, bundle.key, bundle.name, index, bundle.public_send("rcs_media#{index}_id")]
          count += 1
        end
      end
    end
    puts "#{count} template id(s) exported to #{path}"
  end

  desc 'Attach exported text template ids to the matching text bundle messages that have no template yet'
  task :import_template_ids, [:path] => :environment do |_task, args|
    imported = 0
    skipped = []

    CSV.foreach(args[:path] || default_path, headers: true) do |row|
      index = row['message_index'].to_i
      bundles = Media::TextMessagesBundle.kept
      bundle = row['key'].present? ? bundles.find_by(key: row['key']) : bundles.find_by(id: row['bundle_id'], name: row['bundle_name'])
      reason =
        if bundle.nil? then 'bundle not found'
        elsif bundle.public_send("body#{index}").blank? then 'message is empty'
        elsif bundle.public_send("image#{index}_id").present? then 'message has an image'
        elsif bundle.public_send("rcs_media#{index}_id").present? then "already has template #{bundle.public_send("rcs_media#{index}_id")}"
        end

      if reason
        skipped << "Bundle ##{row['bundle_id']} « #{row['bundle_name']} » message #{index} (template #{row['rcs_media_id']}): #{reason}"
        puts skipped.last
      else
        bundle.update_columns("rcs_media#{index}_id" => row['rcs_media_id'].to_i, "rcs_text_template#{index}" => true)
        imported += 1
      end
    end

    puts "\nImported: #{imported}"
    puts "Skipped: #{skipped.size}"
  end
end
