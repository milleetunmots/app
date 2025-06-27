class Airtables::Url < Airrecord::Table

  self.base_key = ENV['AIRTABLE_APPLICATION_BASE_KEY'].freeze
  self.table_name = ENV['AIRTABLE_URL_TABLE_NAME'].freeze

  def self.verified
    all(filter: '{Status} = "Lien vérifié"')
  end
end
