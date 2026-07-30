namespace :keyword_filter do
  desc 'Compte les messages sortants existants qui matcheraient un terme candidat (aide au choix des BlockedPattern)'
  task :audit, [:term] => :environment do |_task, args|
    abort 'Usage: rake "keyword_filter:audit[terme ou expression]"' if args[:term].blank?

    service = BlockedPattern::AuditService.new(args[:term]).call
    puts "#{service.matches_count} message(s) sortant(s) matcheraient « #{args[:term]} »"
    service.excerpts.each { |excerpt| puts "  … #{excerpt} …" }
  end
end
