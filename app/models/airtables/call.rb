class Airtables::Call < Airrecord::Table

  self.base_key = ENV['AIRTABLE_CALLER_BASE_KEY'].freeze
  self.table_name = ENV['AIRTABLE_CALL_TABLE_NAME'].freeze

  has_many :callers, class: "Airtables::Caller", column: "Accompagnantes de cette mission"
  has_many :call_missions, class: "Airtables::CallMission", column: "Suivi V1 (2)"

  def self.all_call_missions
    all(sort: { 'Nom cohorte' => 'asc'}).map { |call| call["Mission d'appels"] }
  end

  def self.call_missions_by_name(name)
    all(filter: "{Mission d'appels} = \"#{name}\"").first.call_missions
  end
end
