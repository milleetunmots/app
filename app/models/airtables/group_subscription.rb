class Airtables::GroupSubscription < Airrecord::Table

  self.base_key = ENV['AIRTABLE_CALLER_BASE_KEY'].freeze
  self.table_name = ENV['AIRTABLE_GROUP_SUBSCRIPTION_TABLE_NAME'].freeze

  def self.validated
    all(filter: '{Statut} = "Validée"')
  end

  def registration_id
    self['ID Inscription']
  end

  def families_count
    self['NB Familles (number)']
  end

  def airtable_caller_id
    self['Appelantes']&.first
  end

  def airtable_cohort_id
    self['Cohortes']&.first
  end
end
