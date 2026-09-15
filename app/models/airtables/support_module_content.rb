class Airtables::SupportModuleContent < Airrecord::Table

  self.base_key = ENV['AIRTABLE_SUPPORT_MODULE_CONTENT_APPLICATION_BASE_KEY'].freeze
  self.table_name = ENV['AIRTABLE_SUPPORT_MODULE_CONTENT_TABLE_NAME'].freeze

  SUPPORT_MODULE_URL_PREFIX = 'https://app.1001mots.org/admin/support_modules/'.freeze

  AGE_RANGE_BY_AIRTABLE_AGE = {
    '04-11 mois' => SupportModule::FOUR_TO_ELEVEN,
    '12-17 mois' => SupportModule::TWELVE_TO_SEVENTEEN,
    '18-23 mois' => SupportModule::EIGHTEEN_TO_TWENTY_THREE,
    '24-29 mois' => SupportModule::TWENTY_FOUR_TO_TWENTY_NINE,
    '30-35 mois' => SupportModule::THIRTY_TO_THIRTY_FIVE,
    '4-10 mois' => SupportModule::FOUR_TO_TEN,
    '11-16 mois' => SupportModule::ELEVEN_TO_SIXTEEN,
    '17-22 mois' => SupportModule::SEVENTEEN_TO_TWENTY_TWO,
    'plus de 22 mois' => SupportModule::TWENTY_THREE_AND_MORE
  }.freeze

  AIRTABLE_AGE_BY_AGE_RANGE = AGE_RANGE_BY_AIRTABLE_AGE.invert.freeze

  # Aucun accès réseau à l'affichage : l'identifiant est synchronisé en amont.
  def self.record_url_for(support_module)
    record_id = support_module&.airtable_content_id
    return if record_id.blank? || base_key.blank? || table_name.blank?

    "https://airtable.com/#{base_key}/shrrFRdYIrDKqvy1u/#{table_name}/viwvzXW4OIZ0flR7h/#{record_id}"
  end

  def self.matches_for(support_module, records)
    airtable_age = AIRTABLE_AGE_BY_AGE_RANGE[support_module.age_ranges&.first]
    return [] if airtable_age.blank?

    title = support_module.name.to_s.strip
    module_url = "#{SUPPORT_MODULE_URL_PREFIX}#{support_module.id}"
    candidates = records.select do |record|
      Array(record['Age']) == [airtable_age] &&
        (record.title == title || record['SMS envoyés'] == module_url)
    end

    same_title = candidates.select { |record| record.title == title }
    same_title.presence || candidates
  end

  def title
    self['titre'].to_s.strip
  end
end
