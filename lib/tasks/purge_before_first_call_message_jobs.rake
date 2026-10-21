require 'sidekiq/api'

# One-shot, à exécuter en production juste après le déploiement de rdv_for_callers (date : JJ/MM/AAAA à renseigner).
# Parent::SendBeforeFirstCallMessageJob n'existe plus : ses occurrences déjà planifiées,
# en retry ou mortes échoueraient à la désérialisation.
#   rake sidekiq:purge_before_first_call_message_jobs          (dry-run)
#   rake "sidekiq:purge_before_first_call_message_jobs[apply]"
namespace :sidekiq do
  desc 'Purge les Parent::SendBeforeFirstCallMessageJob restants dans Sidekiq. Dry-run sauf avec l\'argument "apply".'
  task :purge_before_first_call_message_jobs, [:mode] => :environment do |_t, args|
    abort 'ERREUR : tâche réservée à la production' unless Rails.env.production?

    apply = args[:mode] == 'apply'
    job_class = 'Parent::SendBeforeFirstCallMessageJob'
    puts "=== Purge des #{job_class}#{' (DRY-RUN)' unless apply} ==="

    # Les jobs ActiveJob portent leur classe dans le premier argument Sidekiq.
    targeted = ->(set) { set.select { |entry| entry.args.first.is_a?(Hash) && entry.args.first['job_class'] == job_class } }

    entries = {
      'planifiés' => targeted.call(Sidekiq::ScheduledSet.new),
      'en retry' => targeted.call(Sidekiq::RetrySet.new),
      'morts' => targeted.call(Sidekiq::DeadSet.new)
    }
    puts entries.map { |label, found| "#{label} : #{found.size}" }.join(' - ')

    entries.each_value { |found| found.each(&:delete) } if apply
  end
end
