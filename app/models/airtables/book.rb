class Airtables::Book < Airrecord::Table

  self.base_key = ENV['AIRTABLE_APPLICATION_BASE_KEY'].freeze
  self.table_name = ENV['AIRTABLE_BOOK_TABLE_NAME'].freeze

end
