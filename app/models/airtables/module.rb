class Airtables::Module < Airrecord::Table

  self.base_key = ENV['AIRTABLE_APPLICATION_BASE_KEY'].freeze
  self.table_name = ENV['AIRTABLE_MODULE_TABLE_NAME'].freeze

  def ages
    case self['age']
    when '04-11 mois'
      SupportModule::FOUR_TO_ELEVEN
    when '12-17 mois'
      SupportModule::TWELVE_TO_SEVENTEEN
    when '18-23 mois'
      SupportModule::EIGHTEEN_TO_TWENTY_THREE
    when '24-29 mois'
      SupportModule::TWENTY_FOUR_TO_TWENTY_NINE
    when '30-35 mois'
      SupportModule::THIRTY_TO_THIRTY_FIVE
    when '0-4 mois'
      nil
    when '4-10 mois'
      SupportModule::FOUR_TO_TEN
    when '11-16 mois'
      SupportModule::ELEVEN_TO_SIXTEEN
    when '17-22 mois'
      SupportModule::SEVENTEEN_TO_TWENTY_TWO
    when 'plus de 22 mois'
      SupportModule::TWENTY_THREE_AND_MORE
    end
  end

  def title
    self['titre'].to_s.strip
  end

  # Un module de la base est identifié côté Airtable par son titre et sa tranche
  # d'âge : il existe plusieurs modules homonymes ne différant que par l'âge.
  def support_module
    SupportModule.find_by(name: title, age_ranges: [ages])
  end

  # URL de l'enregistrement Airtable du module. Airtable résout la vue par
  # défaut de la table : suffisant pour rendre une erreur d'import actionnable.
  def self.record_url(record_id)
    return if record_id.blank?

    "https://airtable.com/#{base_key}/#{table_name}/#{record_id}"
  end
end
