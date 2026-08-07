class Book::SavImportService

  attr_reader :errors, :matched_count

  def initialize(csv_file:)
    @csv_file = csv_file
    @errors = []
    @matched_count = 0
  end

  def call
    CSV.foreach(@csv_file.path, col_sep: ',').with_index do |row, i|
      process_row(row, i + 1)
    end
    self
  end

  private

  def process_row(row, line)
    resent_on = Date.strptime(row[0].to_s.strip, '%d/%m/%Y')
    csm_id = row[1].to_s.strip
    condition = row[2]

    csm = ChildrenSupportModule.find_by(id: csm_id, book_condition: condition)
    if csm.nil?
      @errors << [line, "Aucune fiche trouvée pour l'identifiant #{csm_id} avec le statut #{row[2]}"]
      return
    end

    csm.update_column(:book_resent_on, resent_on)
    @matched_count += 1
  rescue ArgumentError
    @errors << [line, "Date de renvoi invalide : #{row[0]}"]
  end
end
