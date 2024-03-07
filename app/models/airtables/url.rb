class Airtables::Url < Airrecord::Table

  self.base_key = 'app9OVHqyideRP6od'.freeze
  self.table_name = 'tblCCRGXNXRL0WU5P'.freeze

  def self.verified
    all(filter: '{Status} = "Lien vérifié"')
  end
end
