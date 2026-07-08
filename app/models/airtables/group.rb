class Airtables::Group < Airrecord::Table

  self.base_key = ENV['AIRTABLE_CALLER_BASE_KEY'].freeze
  self.table_name = ENV['AIRTABLE_GROUP_TABLE_NAME'].freeze

  def name
    self['ID Cohorte']
  end

  def start_date
    self['Date début']
  end
end
