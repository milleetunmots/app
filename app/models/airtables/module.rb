class Airtables::Module < Airrecord::Table

  self.base_key = 'app9OVHqyideRP6od'.freeze
  self.table_name = 'tblFIP7a8nHHsXtPJ'.freeze

  def ages
    case self['age']
    when '00-05 mois'
      SupportModule::LESS_THAN_FIVE
    when '06-11 mois'
      SupportModule::FIVE_TO_ELEVEN
    when '12-17 mois'
      SupportModule::TWELVE_TO_SEVENTEEN
    when '18-23 mois'
      SupportModule::EIGHTEEN_TO_TWENTY_THREE
    when '24-29 mois'
      SupportModule::TWENTY_FOUR_TO_TWENTY_NINE
    when '30-35 mois'
      SupportModule::THIRTY_TO_THIRTY_FIVE
    when '0-4 mois'
      nil
    when '4-10 mois'
      SupportModule::FOUR_TO_TEN
    when '11-16 mois'
      SupportModule::ELEVEN_TO_SIXTEEN
    when '17-22 mois'
      SupportModule::SEVENTEEN_TO_TWENTY_TWO
    when 'plus de 22 mois'
      SupportModule::TWENTY_THREE_AND_MORE
    end
  end
end
