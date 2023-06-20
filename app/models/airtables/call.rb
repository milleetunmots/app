class Airtables::Call < Airrecord::Table

  self.base_key = 'appDlEdpmapLFJ6B9'.freeze
  self.table_name = 'tblfsmKxURb2ZC33G'.freeze

  has_many :callers, class: "Airtables::Caller", column: "Appelantes de cette mission"
  has_many :call_missions, class: "Airtables::CallMission", column: "Suivi V1 (2)"

  def self.all_call_missions
    all(sort: { 'Nom cohorte' => 'asc'}).map { |call| call["Mission d'appels"] }
  end

  def self.call_missions_by_name(name)
    all(filter: "{Mission d'appels} = \"#{name}\"").first.call_missions
  end
end
