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

  def self.record_url_for(support_module)
    record = for_support_module(support_module)
    return if record.blank?

    "https://airtable.com/#{base_key}/shrrFRdYIrDKqvy1u/#{table_name}/viwvzXW4OIZ0flR7h/#{record.id}"
  end

  def self.for_support_module(support_module)
    return if support_module.blank?

    airtable_age = AIRTABLE_AGE_BY_AGE_RANGE[support_module.age_ranges&.first]
    return if airtable_age.blank?

    title = support_module.name.to_s.strip
    records = all(filter: support_module_filter(airtable_age, title, support_module.id))

    records.find { |record| record.title == title } || records.first
  end

  def self.support_module_filter(airtable_age, title, support_module_id)
    <<~FORMULA.squish
      AND(
        ARRAYJOIN({Age}) = "#{escape(airtable_age)}",
        OR(
          TRIM({titre}) = "#{escape(title)}",
          {SMS envoyés} = "#{SUPPORT_MODULE_URL_PREFIX}#{support_module_id}"
        )
      )
    FORMULA
  end

  def title
    self['titre'].to_s.strip
  end

  # Une valeur interpolée dans une formule Airtable est délimitée par des
  # guillemets : sans échappement, un titre en contenant casserait la formule.
  def self.escape(value)
    value.to_s.gsub(/[\\"]/) { |character| "\\#{character}" }
  end
end
