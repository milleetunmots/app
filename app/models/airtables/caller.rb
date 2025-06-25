class Airtables::Caller < Airrecord::Table

  self.base_key = ENV['AIRTABLE_CALLER_BASE_KEY'].freeze
  self.table_name = ENV['AIRTABLE_CALLER_TABLE_NAME'].freeze

  has_many :call_missions, class: 'Airtables::CallMission', column: "Missions d'appels"

  def self.caller_id_by_airtable_caller_id(airtable_caller_id)
    find(airtable_caller_id)['N° suivi base']
  end
end
