class Place
  class CreatePlaceRecordsService < ApiGoogle::InitializeSheetsService

    def initialize
      super
      @sheet_id = ENV['LAEP_SHEET_ID']
      @sheet_name = ENV['LAEP_SHEET_NAME']
    end

    def call
      super
      return self if @errors.any?

      @response.values.each do |row|
        next unless address = row[3]
        next if address == 'Adresse du LAEP'

        name = row[1].presence || row[0]
        form = Media::Form.find_or_create_by(url: row[5], name: name)
        place_attributes = {
          place_type: 'laep',
          name: name,
          address: address,
          redirection_target_id: form.redirection_target&.id
        }
        next if Place.exists?(place_attributes)

        place = Place.create(place_attributes)
        place.geocode
        place.save
      end
      self
    end
  end
end
