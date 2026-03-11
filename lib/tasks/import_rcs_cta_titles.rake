namespace :rcs do
  desc "Import CTA titles in bulk from an Excel file (.xlsx/.xls). " \
       "Usage: rake rcs:import_cta_titles[path/to/file.xlsx]"
  task :import_cta_titles, [:file_path] => :environment do |_t, args|
    file_path = args[:file_path]

    unless file_path.present?
      puts "Usage: rake rcs:import_cta_titles[path/to/file.xlsx]"
      exit 1
    end

    unless File.exist?(file_path)
      puts "ERROR: File not found: #{file_path}"
      exit 1
    end

    extension = File.extname(file_path).delete('.').to_sym
    puts "Opening file: #{file_path}"

    begin
      spreadsheet = Roo::Spreadsheet.open(file_path, extension: extension)
    rescue => e
      puts "ERROR: Could not open file: #{e.message}"
      exit 1
    end

    sheet = spreadsheet.sheet(0)
    last_row = sheet.last_row

    if last_row.nil? || last_row < 2
      puts "ERROR: File is empty or has no data rows (expected headers on row 1)."
      exit 1
    end

    puts "Processing #{last_row - 1} row(s)..."

    # Column indices :
    # 0=#, 1=Nom, 2=Rcs title1, 3=Message 1, 4=File1, 5=Lien 1, 6=Titre CTA Lien 1,
    # 7=Rcs title2, 8=Message 2, 9=File2, 10=Lien 2, 11=Titre CTA Lien 2,
    # 12=Rcs title3, 13=Message 3, 14=File3, 15=Lien 3, 16=Titre CTA Lien 3
    CTA_COLUMNS = { 1 => 6, 2 => 11, 3 => 16 }.freeze
    BODY_COLUMNS = { 1 => 3, 2 => 8, 3 => 13 }.freeze

    updated_count = 0
    error_count = 0

    (2..last_row).each do |row_number|
      row = sheet.row(row_number)

      trio_id = row[0]&.to_i

      unless trio_id&.positive?
        puts "Ligne #{row_number}: ERREUR - ID de trio manquant ou invalide (#{row[0].inspect})"
        error_count += 1
        next
      end

      cta_titles = CTA_COLUMNS.transform_values { |col| row[col].to_s.strip.presence }
      bodies = BODY_COLUMNS.transform_values { |col| row[col].to_s.strip.presence }

      if cta_titles.values.all?(&:nil?)
        puts "Ligne #{row_number}: SKIP - Trio ##{trio_id} aucun titre CTA renseigné"
        next
      end
      if bodies.values.all?(&:nil?)
        puts "Ligne #{row_number}: SKIP - Trio ##{trio_id} aucun message renseigné"
        next
      end

      bundle = Media::TextMessagesBundle.find_by(id: trio_id)
      unless bundle
        puts "Ligne #{row_number}: ERREUR - Trio SMS ##{trio_id} introuvable"
        error_count += 1
        next
      end

      row_has_error = false

      cta_titles.each do |n, cta_title|
        next if cta_title.nil?

        if cta_title.length > 25
          puts "Ligne #{row_number}: ERREUR - Titre CTA #{n} trop long (#{cta_title.length} car., max 25) : \"#{cta_title}\""
          row_has_error = true
        end
      end

      if row_has_error
        error_count += 1
        next
      end

      updates = cta_titles.each_with_object({}) do |(n, cta_title), h|
        h["rcs_cta_title#{n}"] = cta_title
        h["body#{n}"] = bodies[n]
      end

      bundle.update_columns(updates)

      summary = cta_titles.map { |n, v| "msg#{n}=#{v.inspect || '(vide)'}" }.join(", ")
      puts "Ligne #{row_number}: OK - Trio ##{trio_id} → #{summary}"
      updated_count += 1
    end

    puts "\n" + "=" * 40
    puts "Terminé."
    puts "Mis à jour : #{updated_count}"
    puts "Erreurs    : #{error_count}"
    puts ""
    puts "Note : les templates SpotHit seront mis à jour lors de la prochaine sauvegarde de chaque trio."
  end
end
