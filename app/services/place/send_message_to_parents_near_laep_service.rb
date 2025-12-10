class Place

  class SendMessageToParentsNearLaepService

    MESSAGE =
      <<~MESSAGE.freeze
        1001mots : Bonjour ! Vous connaissez {LAEP} à {CITY} ?
        Les parents qui habitent près de chez vous recommandent ce lieu pour passer un bon moment avec son bébé.
        Il y a plein de jeux que {PRENOM_ENFANT} va adorer, et aussi d'autres bébés pour se faire des copains !
        Voir l'adresse et les horaires : {URL}
      MESSAGE

    def initialize(date: Time.zone.now, hour: '12:30', source_ids: [], max_distance: 10)
      @date = date
      @hour = hour
      @max_distance = max_distance
      @nearest_places = {}
      @errors = []
      @places = Place.laep.geocoded
      @children = Child.active_in_started_group_and_with_geolocated_parents.source_id_in(source_ids).months_lt(48)
    end

    def call
      return self if @places.empty?

      fill_nearest_places
      send_message
      self
    end

    private

    def fill_nearest_places
      @children.find_each do |child|
        distance, nearest_place = @places.map { |place| [child.parent1.distance_from([place.latitude, place.longitude]), place] }.min_by(&:first)
        next if distance > @max_distance

        place = nearest_place.name.parameterize(separator: '_').to_sym
        if @nearest_places[place].present?
          @nearest_places[place][:children_ids] << "child.#{child.id}"
        else
          @nearest_places[place] = {
            name: nearest_place.name,
            city: nearest_place.city,
            url_id: nearest_place.redirection_target_id,
            children_ids: ["child.#{child.id}"]
          }
        end
      end
    end

    def send_message
      @nearest_places.each_value do |place_informations|
        @message = MESSAGE.dup.gsub('{LAEP}', place_informations[:name]).gsub('{CITY}', place_informations[:city])
        @message.gsub!('{URL}', '') if place_informations[:url_id].nil?
        program_message_service = ProgramMessageService.new(
          @date.strftime('%d-%m-%Y'),
          @hour,
          place_informations[:children_ids],
          @message,
          nil,
          place_informations[:url_id]
        ).call
        @errors << program_message_service.errors if program_message_service.errors
      end
    end
  end
end
