# lib/tasks/db_sanitize.rake
namespace :db do
  desc 'Prune data to recent groups and anonymize all PII — staging use only'
  task sanitize: :environment do
    months = ENV.fetch('SANITIZE_MONTHS_TO_KEEP', '12').to_i

    puts "[db:sanitize] Pruning data older than #{months} months..."
    DbSanitizer::Pruner.new(months).call

    puts "[db:sanitize] Anonymizing PII..."
    DbSanitizer::Anonymizer.new.call

    puts "[db:sanitize] Sanitizing admin accounts..."
    DbSanitizer::AdminSanitizer.new.call

    puts "[db:sanitize] Done."
  end
end
