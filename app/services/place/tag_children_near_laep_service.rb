class Place

  class TagChildrenNearLaepService

    TAG = 'SMS LAEP Moselle'.freeze

    def initialize(source_ids: [], max_distance: 10)
      @max_distance = max_distance
      @places = Place.laep.geocoded
      @children = Child.active_in_started_group_and_with_geolocated_parents.source_id_in(source_ids).months_lt(48)
    end

    def call
      return self if @places.empty?

      tag_children
      self
    end

    private

    def tag_children
      @children.find_each do |child|
        distance = @places.map { |place| child.parent1.distance_from([place.latitude, place.longitude]) }.min
        next if distance > @max_distance

        child.tag_list += [TAG]
        child.save(validate: false)
      end
    end
  end
end
