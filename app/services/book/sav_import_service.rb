class Book::SavImportService

  DATE_FORMAT = '%d/%m/%Y'.freeze

  attr_reader :errors, :matched_count

  def initialize(csv_file:)
    @csv_file = csv_file
    @errors = []
    @matched_count = 0
  end

  def call
    CSV.foreach(@csv_file.path, col_sep: ',').with_index do |row, i|
      next if i.zero? # ligne d'entête
      next if row.all?(&:blank?)

      process_row(row, i + 1)
    end
    self
  end

  private

  def process_row(row, line)
    resent_on = parse_resent_on(row[0].to_s.strip)
    return @errors << [line, "Date de renvoi invalide : #{row[0]}"] if resent_on.nil?

    csm_id = row[1].to_s.strip
    return @errors << [line, "Identifiant invalide : #{row[1]}"] unless csm_id.match?(/\A\d+\z/)

    condition = row[2].to_s.strip
    return @errors << [line, "Statut du livre invalide : #{row[2]}"] unless ChildrenSupportModule::CONDITIONS.include?(condition)

    csm = ChildrenSupportModule.find_by(id: csm_id, book_condition: condition)
    if csm.nil?
      @errors << [line, "Aucune fiche trouvée pour l'identifiant #{csm_id} avec le statut #{condition}"]
      return
    end

    csm.update_column(:book_resent_on, resent_on)
    @matched_count += 1
  end

  # Le format est vérifié avant le parsing : Date.strptime accepte sinon
  # silencieusement une année sur 2 chiffres ("05/08/26" => an 26) ou du
  # texte résiduel après la date.
  def parse_resent_on(value)
    return nil unless value.match?(%r{\A\d{1,2}/\d{1,2}/\d{4}\z})

    Date.strptime(value, DATE_FORMAT)
  rescue Date::Error
    nil
  end
end
