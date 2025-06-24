class Airtables::CallMission < Airrecord::Table

  self.base_key = ENV['AIRTABLE_CALLER_BASE_KEY'].freeze
  self.table_name = ENV['AIRTABLE_CALL_MISSION_TABLE_NAME'].freeze

  belongs_to :caller, class: 'Airtable::Caller', column: 'Appelantes'

  def child_supports_count
    self['Nb familles']
  end

  def airtable_caller_id
    self['Appelantes'].first
  end

  def age_range
    self["Tranche d'âge à privilégier"]&.first
  end
end
