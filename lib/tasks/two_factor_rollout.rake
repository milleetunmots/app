require 'csv'

# Généralisation de la 2FA aux comptes admin, opération ponctuelle :
#   1. rake admin_users:import_phone_numbers CSV_CONTENT="<contenu du CSV>"           (dry-run)
#      rake "admin_users:import_phone_numbers[apply]" CSV_CONTENT="<contenu du CSV>"
#   2. rake admin_users:enable_two_factor                                              (dry-run)
#      rake "admin_users:enable_two_factor[apply]"
#
# CSV_CONTENT : colonnes Nom, Prénom, Email, Téléphone, séparées par tabulation
# (copier-coller Google Sheets), « ; » ou « , ». Le contenu passe par une
# variable d'environnement et non un argument rake, qui coupe sur les virgules.
#
# Les numéros ne sortent que masqués : la sortie peut finir dans des logs.
namespace :admin_users do
  normalize = ->(value) { I18n.transliterate(value.to_s).downcase.squish }
  mask = ->(phone) { "•• •• •• •• #{phone.to_s.last(2)}" }

  desc 'Importe les mobiles des comptes admin depuis le CSV (Nom, Prénom, Téléphone) passé dans CSV_CONTENT. Dry-run sauf si l\'argument vaut "apply".'
  task :import_phone_numbers, [:mode] => :environment do |_t, args|
    dry_run = args[:mode] != 'apply'
    puts "=== Import des numéros de téléphone#{' — DRY-RUN, rien n\'est écrit' if dry_run} ==="

    # ENV est dans l'encodage de la locale, souvent ASCII dans un conteneur :
    # on force l'UTF-8 pour que « Prénom » et les accents des noms survivent.
    content = ENV['CSV_CONTENT'].to_s.dup.force_encoding(Encoding::UTF_8).delete_prefix([0xFEFF].pack('U')).strip
    abort 'ERREUR : CSV_CONTENT est vide' if content.empty?

    # Un copier-coller depuis Google Sheets sépare par tabulation, un export
    # Excel français par « ; », un export CSV classique par « , ».
    first_line = content.lines.first
    col_sep = ["\t", ';', ','].max_by { |separator| first_line.count(separator) }
    rows = CSV.parse(content, headers: true, col_sep: col_sep, header_converters: normalize)
    missing = %w[nom prenom email telephone] - rows.headers.compact
    abort "ERREUR : colonnes manquantes : #{missing.join(', ')} (trouvées : #{rows.headers.compact.join(', ')})" if missing.any?

    # Correspondance par email d'abord. À défaut (adresse perso dans le fichier),
    # par `name`, sans accents ni casse, dans les deux ordres « Prénom Nom » et
    # « Nom Prénom » : ces lignes sont listées à part pour contrôle.
    admin_users = AdminUser.all.to_a
    admin_users_by_email = admin_users.index_by { |admin_user| admin_user.email.downcase }
    admin_users_by_name = admin_users.group_by { |admin_user| normalize.call(admin_user.name) }
    seen_ids = Set.new
    report = Hash.new { |hash, key| hash[key] = [] }

    rows.each.with_index(2) do |row, line|
      first_name = row['prenom'].to_s.squish
      last_name = row['nom'].to_s.squish
      label = "ligne #{line} : #{first_name} #{last_name} <#{row['email'].to_s.strip}>"

      phone = Phonelib.parse(row['telephone'].to_s, :fr)
      unless phone.valid_for_country?(:fr) && phone.types.include?(:mobile)
        report[:invalid_phone] << "#{label} (« #{row['telephone']} » n'est pas un mobile français)"
        next
      end

      email = row['email'].to_s.strip.downcase
      matches = Array(admin_users_by_email[email])
      if matches.empty?
        names = ["#{first_name} #{last_name}", "#{last_name} #{first_name}"].map(&normalize).uniq
        matches = names.flat_map { |name| admin_users_by_name.fetch(name, []) }.uniq
        matched_by_name = true
      end
      active_matches = matches.reject(&:is_disabled)

      if active_matches.size > 1
        report[:ambiguous] << "#{label} (#{active_matches.map(&:email).join(', ')})"
        next
      elsif active_matches.empty?
        report[matches.any? ? :skipped_disabled : :not_found] << label
        next
      end

      admin_user = active_matches.first
      label = "ligne #{line} : #{admin_user.name} <#{admin_user.email}>"
      unless seen_ids.add?(admin_user.id)
        report[:duplicate] << label
        next
      end
      report[:matched_by_name] << "#{label} (email du fichier : #{row['email'].presence || 'vide'})" if matched_by_name

      # Le fichier fait foi : un numéro existant différent est remplacé.
      old_phone = admin_user.phone_number.presence
      new_phone = phone.e164
      if old_phone == new_phone
        report[:unchanged] << "#{label} #{mask.call(new_phone)}"
        next
      end

      status = old_phone ? :replaced : :updated
      begin
        admin_user.update!(phone_number: new_phone) unless dry_run
        report[status] << "#{label} #{"#{mask.call(old_phone)} → " if old_phone}#{mask.call(new_phone)}"
      rescue ActiveRecord::RecordInvalid => e
        report[:failed] << "#{label} (#{e.record.errors.full_messages.to_sentence})"
      end
    end

    {
      updated: 'Numéro ajouté',
      replaced: 'Numéro remplacé',
      unchanged: 'Numéro inchangé',
      not_found: 'Compte introuvable',
      ambiguous: 'Plusieurs comptes possibles',
      invalid_phone: 'Numéro invalide',
      skipped_disabled: 'Compte désactivé, ignoré',
      duplicate: 'Doublon dans le fichier',
      failed: "Échec de l'enregistrement",
      matched_by_name: 'À vérifier : trouvé par le nom, pas par l\'email'
    }.each do |status, title|
      next if report[status].empty?

      puts '', "## #{title} (#{report[status].size})"
      report[status].each { |entry| puts "- #{entry}" }
    end
    puts '', "#{rows.size} lignes lues"
  end

  # `update!` compte par compte, et non `update_all` : le callback
  # `forget_remembered_sessions` doit tourner pour que les cookies « se souvenir
  # de moi » déjà posés n'échappent pas au second facteur.
  desc 'Active la 2FA pour les comptes actifs ayant un mobile. Dry-run sauf si l\'argument vaut "apply".'
  task :enable_two_factor, [:mode] => :environment do |_t, args|
    dry_run = args[:mode] != 'apply'
    puts "=== Activation de la 2FA#{' — DRY-RUN, rien n\'est écrit' if dry_run} ==="

    active_accounts = AdminUser.account_not_disabled
    already_enabled_count = active_accounts.where(two_factor_enabled: true).count
    without_phone = active_accounts.where(phone_number: [nil, '']).order(:name)
    enabled = []
    failed = []

    active_accounts.where(two_factor_enabled: false).where.not(phone_number: [nil, '']).order(:name).each do |admin_user|
      admin_user.update!(two_factor_enabled: true) unless dry_run
      enabled << "##{admin_user.id} #{admin_user.name} <#{admin_user.email}> #{mask.call(admin_user.phone_number)}"
    rescue ActiveRecord::RecordInvalid => e
      failed << "##{admin_user.id} #{admin_user.name} <#{admin_user.email}> (#{e.record.errors.full_messages.to_sentence})"
    end

    puts '', "## #{dry_run ? 'À activer' : 'Activés'} (#{enabled.size})"
    enabled.each { |entry| puts "- #{entry}" }
    if failed.any?
      puts '', "## Échecs (#{failed.size})"
      failed.each { |entry| puts "- #{entry}" }
    end
    puts '', "## Comptes actifs sans numéro, restent sans 2FA (#{without_phone.size})"
    without_phone.each { |admin_user| puts "- #{admin_user.name} <#{admin_user.email}>" }
    puts '', "#{already_enabled_count} comptes avaient déjà la 2FA avant ce passage"
  end
end
