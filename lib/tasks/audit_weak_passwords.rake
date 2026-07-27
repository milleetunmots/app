namespace :admin_users do
  desc 'Audite les AdminUser à mot de passe faible. Arg optionnel : chemin d\'une wordlist. Sortie terminal, aucun clair.'
  task :audit_weak_passwords, [:wordlist_path] => :environment do |_t, args|
    progress = ->(done, total) do
      $stderr.print("\r  audit: #{done}/#{total} comptes")
      $stderr.puts if done == total
    end

    findings = AdminUser::WeakPasswordAuditService.new(
      wordlist_path: args[:wordlist_path],
      progress: progress
    ).call

    total = AdminUser.count
    puts AdminUser::WeakPasswordAuditReporter.render(findings: findings, total: total)
  end
end
