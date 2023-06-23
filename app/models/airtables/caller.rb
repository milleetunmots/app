class Airtables::Caller < Airrecord::Table

  self.base_key = 'appDlEdpmapLFJ6B9'.freeze
  self.table_name = 'tblHAspFrqJq9u9hU'.freeze

  has_many :call_missions, class: "Airtables::CallMission", column: "Missions d'appels"

  def self.caller_id_by_airtable_caller_id(airtable_caller_id)
    find(airtable_caller_id)["N° suivi base"]
  end
end
