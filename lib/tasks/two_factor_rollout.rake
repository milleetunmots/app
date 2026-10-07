require 'csv'

# Généralisation de la 2FA aux comptes admin, opération ponctuelle :
#   1. rake admin_users:import_phone_numbers CSV_CONTENT="<copier-coller Google Sheets>"   (dry-run)
#      rake "admin_users:import_phone_numbers[apply]" CSV_CONTENT="..."
#   2. rake admin_users:enable_two_factor                                                   (dry-run)
#      rake "admin_users:enable_two_factor[apply]"
#
# CSV_CONTENT : colonnes séparées par tabulation, dont « Email » et « Téléphone ».
# Variable d'environnement plutôt qu'argument rake, qui coupe sur les virgules.
# Les numéros ne sortent que masqués : la sortie peut finir dans des logs.
namespace :admin_users do
  desc 'Importe les mobiles des comptes admin depuis CSV_CONTENT. Dry-run sauf avec l\'argument "apply".'
  task :import_phone_numbers, [:mode] => :environment do |_t, args|
    apply = args[:mode] == 'apply'
    puts "=== Import des numéros#{' (DRY-RUN)' unless apply} ==="

    # ENV arrive souvent en ASCII dans un conteneur : sans UTF-8, l'en-tête « Téléphone » est illisible.
    content = ENV['CSV_CONTENT'].to_s.dup.force_encoding(Encoding::UTF_8).strip
    abort 'ERREUR : CSV_CONTENT est vide' if content.empty?

    rows = CSV.parse(content, headers: true, col_sep: "\t")
    missing = %w[Email Téléphone] - rows.headers
    abort "ERREUR : colonnes manquantes : #{missing.join(', ')}" if missing.any?

    updated = []
    errors = []
    unchanged = 0

    rows.each.with_index(2) do |row, line|
      email = row['Email'].to_s.strip
      admin_user = AdminUser.account_not_disabled.find_by('LOWER(email) = ?', email.downcase)
      next errors << "ligne #{line} <#{email}> : compte actif introuvable" unless admin_user

      # e164 vaut nil pour une saisie illisible : sans ce garde-fou, allow_blank laisserait effacer le numéro existant.
      phone_number = Phonelib.parse(row['Téléphone']).e164
      next errors << "ligne #{line} <#{email}> : numéro illisible" unless phone_number

      admin_user.phone_number = phone_number
      next unchanged += 1 unless admin_user.phone_number_changed?
      next errors << "ligne #{line} <#{email}> : #{admin_user.errors.full_messages.to_sentence}" if admin_user.invalid?

      updated << "#{admin_user.email} #{admin_user.masked_phone_number}#{' (remplace un numéro existant)' if admin_user.phone_number_was.present?}"
      admin_user.save! if apply
    end

    puts '', "## #{apply ? 'Mis à jour' : 'À mettre à jour'} (#{updated.size})", *updated.map { |entry| "- #{entry}" }
    puts '', "## Erreurs (#{errors.size})", *errors.map { |entry| "- #{entry}" }
    puts '', "#{unchanged} numéros déjà à jour"
  end

  # `update!` compte par compte, et non `update_all` : le callback `forget_remembered_sessions`
  # doit tourner pour que les cookies « se souvenir de moi » déjà posés n'échappent pas au second facteur.
  desc 'Active la 2FA des comptes actifs ayant un mobile. Dry-run sauf avec l\'argument "apply".'
  task :enable_two_factor, [:mode] => :environment do |_t, args|
    apply = args[:mode] == 'apply'
    puts "=== Activation de la 2FA#{' (DRY-RUN)' unless apply} ==="

    accounts = AdminUser.account_not_disabled.where(two_factor_enabled: false)

    puts '', "## #{apply ? 'Activés' : 'À activer'}"
    accounts.where.not(phone_number: [nil, '']).find_each do |admin_user|
      puts "- #{admin_user.name} <#{admin_user.email}> #{admin_user.masked_phone_number}"
      admin_user.update!(two_factor_enabled: true) if apply
    end

    puts '', '## Restent sans 2FA, faute de numéro'
    accounts.where(phone_number: [nil, '']).find_each { |admin_user| puts "- #{admin_user.name} <#{admin_user.email}>" }
  end
end
