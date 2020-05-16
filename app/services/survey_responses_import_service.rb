class SurveyResponsesImportService

  attr_reader :errors

  def initialize(survey_name:, csv_file:)
    @survey_name = survey_name
    @csv_file = csv_file
    @errors = []
  end

  def call
    Events::SurveyResponse.transaction do
      CSV.foreach(@csv_file.path, headers: true, col_sep: ',').with_index do |row, i|
        line = i + 2
        # puts "line #{line}"
        # puts row.inspect

        values = row.to_h

        # parent

        phone_number = format_phone_number(values.delete('phone_number')&.strip)
        if phone_number.blank?
          @errors << [line, ['Numéro de téléphone incorrect']]
          puts 'error: Numéro de téléphone incorrect'
          raise ActiveRecord::Rollback
        end

        parent = Parent.find_by_phone_number(phone_number)
        if parent.nil?
          @errors << [line, ['Numéro de téléphone inconnu']]
          puts 'error: Numéro de téléphone inconnu'
          raise ActiveRecord::Rollback
        end

        # base

        attributes = {
          related: parent,
          occurred_at: DateTime.parse(values.delete('Horodateur')&.strip),
          survey_name: @survey_name,
          body: values.map{|k,v| [k,v].join(': ')}.join("\n")
        }

        # puts "attributes:", attributes.inspect
        survey_response = Events::SurveyResponse.new(attributes)
        unless survey_response.save
          @errors << [line, survey_response.errors.full_messages]
          puts "error: #{survey_response.errors.inspect}"
          raise ActiveRecord::Rollback
        end
      end
    end
    self
  end

  def format_phone_number(phone_number)
    return nil if phone_number.blank?
    phone = Phonelib.parse(
      [
        phone_number[0] == '0' ? '' : '0',
        phone_number
      ].join
    )
    phone.e164
  end

end
