class Airtables::Call < Airrecord::Table

  self.base_key = 'appDlEdpmapLFJ6B9'.freeze
  self.table_name = 'tblfsmKxURb2ZC33G'.freeze

  has_many :callers, class: "Airtables::Caller", column: "Appelantes de cette mission"

  def self.all_call_names
    all.map { |call| call["Nom cohorte"] }
  end
end
