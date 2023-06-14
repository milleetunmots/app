class Airtables::CallMission < Airrecord::Table

  self.base_key = 'appDlEdpmapLFJ6B9'.freeze
  self.table_name = "tblFpJWY8uZ4XLAYR".freeze

  belongs_to :caller, class: "Airtable::Caller", column: "Appelantes"

  def child_supports_count
    self["Nb familles"]
  end

end
