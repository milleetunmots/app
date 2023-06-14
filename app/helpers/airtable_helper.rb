module AirtableHelper

  Airrecord.api_key = ENV['AIRTABLE_TOKEN']

  class Caller < Airrecord::Table
    self.base_key = ENV['CALLER_KEY']
    self.table_name = ENV['CALLER_TABLE_NAME']

  end
end
