class Place

  class SendMessageToMoselleParentsService

    MESSAGE =
      <<~MESSAGE.freeze
        1001mots : Bonjour ! Vous connaissez {LAEP} à {CITY} ?
        Les parents qui habitent près de chez vous recommandent ce lieu pour passer un bon moment avec son bébé.
        Il y a plein de jeux que {PRENOM_ENFANT} va adorer, et aussi d'autres bébés pour se faire des copains !
        Voir l'adresse et les horaires : {URL}
      MESSAGE
    # REFERENCE_DATE = Date.new(2025, 11, 30)
    # MIN_REGISTRATION_SINCE = 2.months
    # MAX_REGISTRATION_SINCE = 2.years
    MAX_DISTANCE_KM = 10


    def initialize
      @nearest_places = {}
      @errors = []
      @places = Place.laep.geocoded
      # @range = (REFERENCE_DATE - MAX_REGISTRATION_SINCE).beginning_of_day..(REFERENCE_DATE - MIN_REGISTRATION_SINCE).end_of_day
    end

    def call
      return self if @places.empty?

      fill_nearest_places
      send_message
      self
    end

    private

    # def parents
      # TO DO
      # latest_child_lateral_sql =
      #   <<~SQL.squish
      #   LATERAL (
      #       SELECT c.*
      #       FROM children c
      #       WHERE c.parent1_id = parents.id
      #       OR c.parent2_id = parents.id
      #       ORDER BY c.birthdate DESC NULLS LAST
      #       LIMIT 1
      #       ) AS lc
      # SQL
      # Parent.geocoded.joins(latest_child_lateral_sql).where(lc: { created_at: @range }).distinct
    # end

    def fill_nearest_places
      Parent.geocoded.find_each do |parent|
        distance, nearest_place = @places.map { |place| [parent.distance_from([place.latitude, place.longitude]), place] }.min_by(&:first)
        next if distance > 10

        place = nearest_place.name.downcase.strip.gsub(/\s+/, '_').to_sym
        if @nearest_places[place].present?
          @nearest_places[place][:parent_ids] << "parent.#{parent.id}"
        else
          @nearest_places[place] = {
            name: nearest_place.name,
            city: nearest_place.city,
            url_id: nearest_place.redirection_target_id,
            parent_ids: ["parent.#{parent.id}"]
          }
        end
      end
    end

    def send_message
      @nearest_places.each do |_, place_informations|
        @message = MESSAGE.dup.gsub('{LAEP}', place_informations[:name]).gsub('{CITY}', place_informations[:city])
        @message.gsub!('{URL}', '') if place_informations[:url_id].nil?
        program_message_service = ProgramMessageService.new(
          Time.zone.now.strftime('%d-%m-%Y'),
          '12:30',
          place_informations[:parent_ids],
          @message,
          nil,
          place_informations[:url_id]
        ).call
        @errors << program_message_service.errors if program_message_service.errors
      end
    end
  end
end
